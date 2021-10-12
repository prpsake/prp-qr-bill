/*

Links:
https://www.paymentstandards.ch/dam/downloads/ig-qr-bill-en.pdf#page=28
https://regex101.com/

*/

type jsonEntry = (string, Js.Json.t)
type entry = (string, string)



type validationError<'a> =
  {
    key: string,
    val: 'a,
    msg: array<string>,
    display: string
  }



type rec validationSuccess =
  {
    key: string,
    val: string
  }



type validationResult<'a> = 
  | Ok(validationSuccess)
  | Error(validationError<'a>)



/**

`mod97FromString(str)`

Gratefully taken from https://github.com/arhs/iban.js/blob/master/iban.js#L71

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



let concatResult: validationResult<'a> => validationResult<'a> => validationResult<'a> =
  result =>
  otherResult =>
  switch result {
  | Ok({key, val}) =>
    switch otherResult {
    | Ok({ val as otherVal }) => Ok({key, val: val++ " " ++otherVal})
    | Error(err) => Error(err)
    }
  | Error(err) =>
    switch otherResult {
    | Ok(_) => Error(err)
    | Error({key, val, msg, display}) => 
      Error({key, val, msg: Js.Array.concat(msg, err.msg), display})
    }
  }



let entryKey: validationResult<'a> => string => validationResult<'a> =
  result =>
  key =>
  switch result {
  | Ok({val}) => Ok({key, val})
  | Error({val, msg, display}) => Error({key, val, msg, display})
  }



let entryFromValidationResult: validationResult<'a> => entry =
  result =>
  switch result {
  | Ok({key, val}) => (key, val)
  | Error(err) => (err.key, err.display)
  }



let valueFromJsonEntry: Js.Dict.t<Js.Json.t> => string => validationResult<'a> =
  data =>
  key =>
  switch Js.Dict.get(data, key) {
  | Some(val) =>
    switch Js.Json.classify(val) {
    | JSONString(x) => Ok({key, val: x})
    | _ => 
      Error({key, val: "", msg: ["is not a string"], display: "" })
    }
  | None =>
    Error({key, val: "", msg: ["is not a string"], display: "" })
  }



let validateWithRe: validationResult<'a> => (string => option<array<string>>) => string => validationResult<'a> =
  result =>
  fn =>
  errMsg =>
  switch result {
  | Ok({key, val}) =>
    switch fn(val) {
    | Some(xs) => Ok({key, val: xs[0]})
    | None =>
      Error({key, val, msg: [errMsg], display: "" })
    }
  | Error(err) => Error(err)
  }



// let errorDisplay: validationResult<'a> => string => validationResult<'a> =
//   result =>
//   display =>
//   switch result {
//   | Ok(ok) => Ok(ok)
//   | Error({key, val, msg}) => Error({key, val, msg, display})
//   }



let validateIban: validationResult<'a> => validationResult<'a> =
  result =>
  switch result {
  | Ok({key, val}) => {
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
      x == 1 ? Ok({key, val}) : Error({
        key,
        val,
        msg: ["fails on the checksum: expected 1 but got " ++Belt.Int.toString(x)],
        display: ""
      })
    }
  | Error(err) => Error(err)
  }



let validateFromReferenceType: validationResult<'a> => validationResult<'a> => validationResult<'a> =
  result =>
  otherResult =>
  switch result {
  | Ok({key, val}) =>
    let (_, v) = otherResult->entryFromValidationResult
    switch Js.Types.classify(v) {
    | JSString(v) => v
    | _ => ""
    }
    ->referenceType =>
      switch referenceType {
      | "QRR" =>
        mod10FromIntString(val)
        ->a => {
          let b = Js.String2.sliceToEnd(val, ~from=26)
          a == b ?
          Ok({key, val}) :
          Error({
            key,
            val,
            msg: ["fails on the check digit: expected" ++b++ " but got " ++a],
            display: ""
          })
        }
      | "SCOR" => Ok({key, val}) //TODO: validation
      | "NON" =>
        val === "" ? 
        Ok({key, val}) :
        Error({
          key,
          val,
          msg: ["got removed as the reference type was determined as NON"],
          display: ""
        })
      | _ =>
        Error({
          key,
          val,
          msg: ["fails before calculating the check digit as no reference type could be determined"],
          display: ""
        })
      }
  | Error(err) => Error(err)
  }



let validateFromAddressType: validationResult<'a> => (~coerceValS: string=?, ~coerceValK: string=?) => validationResult<'a> => validationResult<'a> =
  result =>
  (~coerceValS=?, ~coerceValK=?) =>
  otherResult =>
  switch result {
  | Ok({key, val}) =>
    let (_, v) = otherResult->entryFromValidationResult
    switch Js.Types.classify(v) {
    | JSString(v) => v
    | _ => ""
    }
    ->addressType =>
      switch addressType {
      | "S" =>
        switch coerceValS {
        | Some(x) =>
          x === val ?
          Ok({key, val}) :
          Error({
            key,
            val,
            msg: ["got removed as the address type was determined as S"],
            display: x
          })
        | None => Ok({key, val})
        } 
      | "K" =>
        switch coerceValK {
        | Some(x) =>
          x === val ?
          Ok({key, val}) :
          Error({
            key,
            val,
            msg: ["got removed as the address type was determined as K"],
            display: x
          })
        | None => Ok({key, val})
        } 
      | _ =>
        Error({
          key,
          val,
          msg: ["fails before validation by address type as no address type could be determined"],
          display: ""
        })
      }
  | Error(err) => Error(err)
  }



let validateEntries: array<jsonEntry> => array<entry> =
  entries => {
    let data = Js.Dict.fromArray(entries)

    let referenceTypeResult =
      data
      ->valueFromJsonEntry("referenceType")
      ->validateWithRe(
          x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^(QRR|SCOR|NON)$/")), 
          "must be either QRR, SCOR or NON"
        )

    let creditorAddressTypeResult =
      data
      ->valueFromJsonEntry("creditorAddressType")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^(K|S){1}$/")),
          "must be either K or S"
        )

    let debtorAddressTypeResult =
      data
      ->valueFromJsonEntry("debtorAddressType")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^(K|S){1}$/")),
          "must be either K or S"
        )

    let results = [
      data
      ->valueFromJsonEntry("lang")
      ->validateWithRe(
          x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^(en|de|fr|it)$/")),
          "must be either en, de, fr, or it"
        ),

      data
      ->valueFromJsonEntry("currency")
      ->validateWithRe(
          x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^(CHF|EUR)$/")),
          "must be either CHF or EUR"
        ),

      data
      ->valueFromJsonEntry("amount")
      ->validateWithRe(
          x => 
          Formatter.removeWhitespace(x)
          ->Js.Float.fromString
          ->Js.Float.toFixedWithPrecision(~digits=2)
          ->Js.String2.match_(%re("/^([1-9]{1}[0-9]{0,8}\.[0-9]{2}|0\.[0-9]{1}[1-9]{1})$/")),
          "must be a number ranging from 0.01 to 999999999.99"
        ),

      data
      ->valueFromJsonEntry("iban")
      ->validateWithRe(
          x => 
          Formatter.removeWhitespace(x)
          ->Js.String2.toUpperCase
          ->Js.String2.match_(%re("/^(CH|LI)[0-9]{19}$/")), 
          "must start with countryCode CH or LI followed by 19 digits (ex. CH1234567890123456789)"
        )
      ->validateIban,

      referenceTypeResult,

      data
      ->valueFromJsonEntry("reference")
      ->validateWithRe(
          x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^[\s\S]{0,27}$/")),
          "must be at most 27 characters long"
        )
      ->validateFromReferenceType(referenceTypeResult),

      data
      ->valueFromJsonEntry("message")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,140}$/")),
          "must be at most 140 characters long"
        ),

      data
      ->valueFromJsonEntry("messageCode")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,140}$/")),
          "must be at most 140 characters long"
        ),

      creditorAddressTypeResult,

      data
      ->valueFromJsonEntry("creditorName")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{1,70}$/")),
          "must not be empty and at most 70 characters long"
        ),

      data
      ->valueFromJsonEntry("creditorStreetNumber")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,16}$/")),
          "must be at most 16 characters long"
        )
      ->validateFromAddressType(creditorAddressTypeResult, ~coerceValK=""),

      data
      ->valueFromJsonEntry("creditorStreet")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,70}$/")),
          "must be at most 70 characters long"
        ),

      data
      ->valueFromJsonEntry("creditorPostOfficeBox")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,70}$/")),
          "must be at most 70 characters long"
        ),

      data
      ->valueFromJsonEntry("creditorPostalCode")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,16}$/")),
          "must be at most 16 characters long"
        )
      ->validateFromAddressType(creditorAddressTypeResult, ~coerceValK=""),

      data
      ->valueFromJsonEntry("creditorLocality")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{1,35}$/")),
          "must not be empty and at most 35 characters long"
        ),

      data
      ->valueFromJsonEntry("creditorCountryCode")
      ->validateWithRe(
          x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^\S{2}$/")),
          "must be 2 characters long"
        ),

      debtorAddressTypeResult,

      data
      ->valueFromJsonEntry("debtorName")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{1,70}$/")),
          "must not be empty and at most 70 characters long"
        ),

      data
      ->valueFromJsonEntry("debtorStreetNumber")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,16}$/")),
          "must be at most 16 characters long"
        )
      ->validateFromAddressType(debtorAddressTypeResult, ~coerceValK=""),

      data
      ->valueFromJsonEntry("debtorStreet")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,70}$/")),
          "must be at most 70 characters long"
        ),

      data
      ->valueFromJsonEntry("debtorPostOfficeBox")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,70}$/")),
          "must be at most 70 characters long"
        ),

      data
      ->valueFromJsonEntry("debtorPostalCode")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,16}$/")),
          "must be at most 16 characters long"
        )
      ->validateFromAddressType(debtorAddressTypeResult, ~coerceValK=""),

      data
      ->valueFromJsonEntry("debtorLocality")
      ->validateWithRe(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{1,35}$/")),
          "must not be empty and at most 35 characters long"
        ),

      data
      ->valueFromJsonEntry("debtorCountryCode")
      ->validateWithRe(
          x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^\S{2}$/")),
          "must be 2 characters long"
        )
    ]



    let errors = 
      Js.Array2.filter(results, 
        x => 
        switch x {
        | Ok(_) => false
        | Error(_) => true
        }
      )



    Js.Array2.forEach(errors,
      x =>
      switch x {
      | Ok(_) => ()
      | Error(err) => Js.log(err.key++ " " ++Js.Array2.joinWith(err.msg, " and "))
      }
    )



    Js.Array2.map(results, entryFromValidationResult)
  }