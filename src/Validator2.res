type dataOption<'a> =
  | User({
      key: string,
      val: 'a
    })
  | Default({
      key: string,
      val: 'a
    })
  | Error({
      @as("type") _type: string,
      key: string,
      val: string,
      msg: string
    })
  | None




type appAddress = {
  addressType: dataOption<string>,
  name: dataOption<string>,
  street: dataOption<string>,
  streetNumber: dataOption<string>,
  postOfficeBox: dataOption<string>,
  postalCode: dataOption<string>,
  locality: dataOption<string>,
  countryCode: dataOption<string>
}



type data = {
  lang: dataOption<string>,
  currency: dataOption<string>,
  amount: dataOption<string>,
  iban: dataOption<string>,
  reference: dataOption<string>,
  message: dataOption<string>,
  messageCode: dataOption<string>,
  creditor: dataOption<appAddress>,
  debtor: dataOption<appAddress>
}



/**

`mod97FromString(str)`

Gratefully taken from https://github.com/arhs/iban.js/blob/master/iban.js#L71
TODO: simplify

*/
let mod97FromString: string => int =
  str => {
    let remainder = ref(str)
    let block = ref("")
    while Js.String.length(remainder.contents) > 2 {
      block := Js.String2.slice(remainder.contents, ~from=0, ~to_=9)
      remainder := 
        switch Belt.Int.fromString(block.contents) {
        | Some(x) => 
          Belt.Int.toString(mod(x, 97))
          ++Js.String2.sliceToEnd(remainder.contents, ~from=Js.String.length(block.contents))
        | None => ""
        }
    }

    switch Belt.Int.fromString(remainder.contents) {
    | Some(x) => mod(x, 97)
    | None => -1
    }
  }



/**

`mod10FromIntegerString(str)`

Gratefully taken from https://www.hosang.ch/modulo10.aspx via
https://github.com/NicolasZanotti/esr-code-line/blob/master/src/index.ts#L10
TODO: simplify

*/
let mod10FromIntString: string => string =
  str => {
    let carry = ref(0)
    let ints = 
      Js.String2.split(str, "")
      ->Js.Array2.map(
        x =>
        switch Belt.Int.fromString(x) {
        | Some(x) => x
        | None => -1
        }
      )

    for i in 0 to (Js.Array.length(ints) - 1) {
      let j = mod(carry.contents + Js.Array2.unsafe_get(ints, i), 10)
      carry := Js.Array2.unsafe_get([0, 9, 4, 6, 8, 2, 7, 1, 3, 5], j)
    }

    Belt.Int.toString(mod((10 - carry.contents), 10))
  }



let validateWithRexp: dataOption<string> => (string => option<array<string>>) => string => dataOption<string> =
  o =>
  fn =>
  msg =>
  switch o {
  | User({ key, val }) => 
    switch fn(val) {
    | Some(xs) => 
      User({ key, val: xs[0] })
    | None =>
      Error({ _type: "Validator", key, val, msg })
    }
  | t => t
  }



let validateWithPred: dataOption<'a> => (string => bool) => string => dataOption<'a> =
  o =>
  fn =>
  msg =>
  switch o {
  | User({ key, val }) =>
    fn(val) ? 
    User({ key, val }) 
    : 
    Error({ _type: "Validator", key, val, msg })
  | t => t
  }



let validateIban: dataOption<string> => dataOption<string> =
  o =>
  switch o {
  | User({ key, val }) => {
    let codeA = Js.String2.charCodeAt(`A`, 0)
    let codeZ = Js.String2.charCodeAt(`Z`, 0)
    val
    ->x => (
        Js.String2.sliceToEnd(x, ~from=4) 
        ++Js.String2.substring(x, ~from=0, ~to_=4)
      )
    ->Js.String2.split("")
    ->Js.Array2.map(
        x =>
        Js.String2.charCodeAt(x, 0)
        ->code =>
          code >= codeA && code <= codeZ ?
          Belt.Float.toString(code -. codeA +. 10.0) :
          x
      )
    ->Js.Array2.joinWith("")
    ->mod97FromString
    ->x =>
      x == 1 ? 
      User({key, val}) 
      : Error({
        _type: "Validator", key, val,
        msg: "fails on the checksum: expected 1 but got " ++Belt.Int.toString(x),
      })
    }
  | t => t
  }



let validateData: data => data =
  d =>
  {
    lang: 
      d.lang
      ->validateWithRexp(
          x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^(en|de|fr|it)$/")),
          "must be either en, de, fr, or it"
        ),
    currency: 
      d.currency
      ->validateWithRexp(
          x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^(CHF|EUR)$/")),
          "must be either CHF or EUR"
        ),
    amount: 
      d.amount
      ->validateWithPred(
          x => 
          Formatter.removeWhitespace(x)
          ->Js.Float.fromString
          ->Js.Float.toFixedWithPrecision(~digits=2)
          ->Js.Float.fromString
          ->x => x >= 0.01 && x <= 999999999.99,
          "must be a number ranging from 0.01 to 999999999.99"
        ),
    iban: 
      d.iban
      ->validateWithRexp(
        x => 
        Formatter.removeWhitespace(x)
        ->Js.String2.toUpperCase
        ->Js.String2.match_(%re("/^(CH|LI)[0-9]{19}$/")), 
        "must start with countryCode CH or LI followed by 19 digits (ex. CH1234567890123456789)"
      )
      ->validateIban,
    reference: None,
    message: None,
    messageCode: None,
    creditor: None,
    debtor: None
  }