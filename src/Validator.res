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



let validateWithRexp: Data.dataOption<string> => (string => option<array<string>>) => string => Data.dataOption<string> =
  o =>
  fn =>
  msg =>
  switch o {
  | Data.User({ key, val }) => 
    switch fn(val) {
    | Some(xs) => 
      Data.User({ key, val: xs[0] })
    | None =>
      Data.Error({ _type: "Validator", key, val, msg })
    }
  | t => t
  }



let validateWithPred: Data.dataOption<'a> => (string => bool) => string => Data.dataOption<'a> =
  o =>
  fn =>
  msg =>
  switch o {
  | Data.User({ key, val }) =>
    fn(val) ? 
    Data.User({ key, val }) 
    : 
    Data.Error({ _type: "Validator", key, val, msg })
  | t => t
  }



let validateIban: Data.dataOption<string> => Data.dataOption<string> =
  o =>
  switch o {
  | Data.User({ key, val }) => {
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
      Data.User({ key, val }) 
      : Data.Error({
        _type: "Validator", key, val,
        msg: "fails on the checksum: expected 1 but got " ++Belt.Int.toString(x),
      })
    }
  | t => t
  }



let validateQRR: Data.dataOptionVal<string> => Data.dataOption<string> =
  ({ key, val }) => {
    let valTrim = Formatter.removeWhitespace(val)
    mod10FromIntString(valTrim)
    ->a => {
        let b = Js.String2.sliceToEnd(valTrim, ~from=26)
        a == b ?
        Data.User({ key, val: valTrim }) :
        Data.Error({
          _type: "Validator",
          key,
          val: valTrim,
          msg: "fails on the check digit: expected" ++b++ " but got " ++a,
        })
      }
    ->validateWithRexp(
        x => Js.String2.match_(x, %re("/^\S{27}$/")),
        "must be 27 characters long"
      )
  }



let validateSCOR: Data.dataOptionVal<string> => Data.dataOption<string> =
  ov =>
  Data.User(ov) //TODO: missing actual validation
  ->validateWithRexp(
      x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^\S{5,25}$/")),
      "must be 5 to 25 characters long"
    )



let validateReference:  Data.dataOption<string> => Data.dataOption<string> => Data.dataOption<string> =
  reference =>
  referenceType =>
  switch reference {
  | Data.User({ key, val }) =>
    switch referenceType {
    | Data.User(ov) =>
      switch ov.val {
      | "QRR" => validateQRR({ key, val })
      | "SCOR" => validateSCOR({ key, val })
      | _ =>
        Data.Error({
          _type: "Validator", key, val,
          msg: "fails as no reference type could be determined for a non-empty reference value",
        })
      }
    | t => t
    }
  | t => t
  }



let validateAddressData: Data.dataOption<Data.addressData> => Data.dataOption<Data.addressData> =
  o =>
  switch o {
  | Data.User({ key, val: ad }) =>
    Data.User({
      key,
      val: {
        addressType:
          ad.addressType
          ->validateWithRexp(
              x => Js.String2.trim(x)->Js.String2.match_(%re("/^(K|S){1}$/")),
              "must be either K or S"
            ),
        name:
          ad.name
          ->validateWithRexp(
              x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{1,70}$/")),
              "must not be empty and at most 70 characters long"
            ),
        street: 
          ad.street
          ->validateWithRexp(
              x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,70}$/")),
              " must be at most 70 characters long"
            ),
        streetNumber:
          ad.streetNumber
          ->validateWithRexp(
              x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,16}$/")),
              "must be at most 16 characters long"
            ),
        postOfficeBox:
          ad.postOfficeBox
          ->validateWithRexp(
              x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,70}$/")),
              "must be at most 70 characters long"
            ),
        postalCode:
          ad.postalCode
          ->validateWithRexp(
               x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,16}$/")),
              "must be at most 16 characters long for structured address values"
            ),
        locality:
          ad.locality
          ->validateWithRexp(
               x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{1,35}$/")),
              "must not be empty and at most 35 characters long"
            ),
        countryCode:
          ad.countryCode
          ->validateWithRexp(
              x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^\S{2}$/")),
              "must be 2 characters long"
            )
      }
    })
  | t => t
  }



let validate: Data.data => Data.data =
  d =>
  d.referenceType
  ->validateWithRexp(
      x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^(QRR|SCOR|NON)$/")), 
      "must be either QRR, SCOR or NON"
    )
  ->referenceType =>
    ({
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

      referenceType,
      reference: d.reference->validateReference(referenceType),

      message:
        d.message
        ->validateWithRexp(
            x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,140}$/")),
            "must be at most 140 characters long"
          ),

      messageCode:
        d.messageCode
        ->validateWithRexp(
            x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,140}$/")),
            "must be at most 140 characters long"
          ),

      creditor: d.creditor->validateAddressData,
      debtor: d.debtor->validateAddressData
    } : Data.data)