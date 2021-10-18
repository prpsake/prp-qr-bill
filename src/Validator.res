/*

Links:
https://www.paymentstandards.ch/dam/downloads/ig-qr-bill-en.pdf#page=28

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


let concatResult: validationResult<'a> => validationResult<'a> => validationResult<'a> =
  result =>
  otherResult =>
  switch result {
  | Ok({key, val}) =>
    switch otherResult {
    | Ok({ val as otherVal }) => Ok({key, val: Js.String.trim(val++ " " ++otherVal)})
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



let validateWithRexp: validationResult<'a> => (string => option<array<string>>) => string => validationResult<'a> =
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



let validateWithPred: validationResult<'a> => (string => bool) => string => validationResult<'a> =
  result =>
  fn =>
  errMsg =>
  switch result {
  | Ok({key, val}) =>
    fn(val) ?
    Ok({key, val}) :
    Error({key, val, msg: [errMsg], display: "" })
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



let validateQRR: validationSuccess => validationResult<'a> =
  ({key, val}) => {
    let valTrim = Formatter.removeWhitespace(val)
    mod10FromIntString(valTrim)
    ->a => {
        let b = Js.String2.sliceToEnd(valTrim, ~from=26)
        a == b ?
        Ok({key, val: valTrim}) :
        Error({
          key,
          val: valTrim,
          msg: ["fails on the check digit: expected" ++b++ " but got " ++a],
          display: ""
        })
      }
    ->validateWithRexp(
        x => Js.String2.match_(x, %re("/^\S{27}$/")),
        "must be 27 characters long"
      )
  }



let validateSCOR: validationSuccess => validationResult<'a> =
  ({key, val}) =>
  Ok({key, val}) //TODO: missing actual validation
  ->validateWithRexp(
      x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^\S{5,25}$/")),
      "must be 5 to 25 characters long"
    )



let validateNON: validationSuccess => validationResult<'a> =
  ({key, val}) =>
  val === "" ? 
  Ok({key, val}) :
  Error({
    key,
    val,
    msg: ["got removed as the reference type was determined as NON"],
    display: ""
  })


let validateWithReferenceType: validationResult<'a> => validationResult<'a> => validationResult<'a> =
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
      | "QRR" => validateQRR({key, val})
      | "SCOR" => validateSCOR({key, val})
      | "NON" => validateNON({key, val})
      | _ =>
        Error({
          key,
          val,
          msg: ["fails as no reference type could be determined"],
          display: ""
        })
      }
  | Error(err) => Error(err)
  }



let validateWithAddressType: 
  validationResult<'a> => 
  validationResult<'a> => 
  (validationResult<'a> => validationResult<'a>) =>
  (validationResult<'a> => validationResult<'a>) => 
  validationResult<'a> =
  result =>
  otherResult =>
  fnS =>
  fnK =>
  switch result {
  | Ok({key, val}) =>
    let (_, v) = otherResult->entryFromValidationResult
    switch Js.Types.classify(v) {
    | JSString(v) => v
    | _ => ""
    }
    ->addressType =>
      switch addressType {
      | "S" => fnS(result)
      | "K" => fnK(result)
      | _ =>
        Error({
          key,
          val,
          msg: ["fails as no address type could be determined"],
          display: ""
        })
      }
  | Error(err) => Error(err)
  }



let validateWithPostOfficeBox: validationResult<'a> => validationResult<'a> => validationResult<'a> =
  result =>
  otherResult => {
    let (_, otherVal) = otherResult->entryFromValidationResult
    let postOfficeBox = 
      switch Js.Types.classify(otherVal) {
      | JSString(v) => v
      | _ => ""
      }
    switch result {
    | Ok({key, val}) =>
      postOfficeBox == "" ?
      Ok({key, val}) :
      Error({
        key,
        val,
        msg: ["street and street number values got replaced with the post office box value"],
        display: postOfficeBox
      })
    | Error(err) => 
      postOfficeBox == "" ?
      Error(err) :
      Error({
        key: err.key,
        val: err.val,
        msg: ["street or street number value errored but got replaced with the post office box value anyway"],
        display: postOfficeBox
      })
    }
  }



let validateEntries: array<jsonEntry> => array<entry> =
  entries => {
    let data = Js.Dict.fromArray(entries)

    // validate dependencies
    let referenceTypeResult =
      data
      ->valueFromJsonEntry("referenceType")
      ->validateWithRexp(
          x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^(QRR|SCOR|NON)$/")), 
          "must be either QRR, SCOR or NON"
        )

    let creditorAddressTypeResult =
      data
      ->valueFromJsonEntry("creditorAddressType")
      ->validateWithRexp(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^(K|S){1}$/")),
          "must be either K or S"
        )

    let creditorPostOfficeBoxResult =
      data
      ->valueFromJsonEntry("creditorPostOfficeBox")
      ->validateWithRexp(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,70}$/")),
          "must be at most 70 characters long"
        )

    let debtorAddressTypeResult =
      data
      ->valueFromJsonEntry("debtorAddressType")
      ->validateWithRexp(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^(K|S){1}$/")),
          "must be either K or S"
        )
    
    let debtorPostOfficeBoxResult =
      data
      ->valueFromJsonEntry("debtorPostOfficeBox")
      ->validateWithRexp(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,70}$/")),
          "must be at most 70 characters long"
        )

    // log errors and return results
    [
      referenceTypeResult,

      data
      ->valueFromJsonEntry("lang")
      ->validateWithRexp(
          x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^(en|de|fr|it)$/")),
          "must be either en, de, fr, or it"
        ),

      data
      ->valueFromJsonEntry("currency")
      ->validateWithRexp(
          x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^(CHF|EUR)$/")),
          "must be either CHF or EUR"
        ),

      data
      ->valueFromJsonEntry("amount")
      ->validateWithPred(
          x => 
          Formatter.removeWhitespace(x)
          ->Js.Float.fromString
          ->Js.Float.toFixedWithPrecision(~digits=2)
          ->Js.Float.fromString
          ->x => x >= 0.01 && x <= 999999999.99,
          "must be a number ranging from 0.01 to 999999999.99"
        ),

      data
      ->valueFromJsonEntry("iban")
      ->validateWithRexp(
          x => 
          Formatter.removeWhitespace(x)
          ->Js.String2.toUpperCase
          ->Js.String2.match_(%re("/^(CH|LI)[0-9]{19}$/")), 
          "must start with countryCode CH or LI followed by 19 digits (ex. CH1234567890123456789)"
        )
      ->validateIban,

      data
      ->valueFromJsonEntry("reference")
      ->validateWithReferenceType(referenceTypeResult),

      data
      ->valueFromJsonEntry("message")
      ->validateWithRexp(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,140}$/")),
          "must be at most 140 characters long"
        ),

      data
      ->valueFromJsonEntry("messageCode")
      ->validateWithRexp(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,140}$/")),
          "must be at most 140 characters long"
        ),

      data
      ->valueFromJsonEntry("creditorName")
      ->validateWithRexp(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{1,70}$/")),
          "must not be empty and at most 70 characters long"
        ),

      data
      ->valueFromJsonEntry("creditorStreet")
      ->validateWithRexp(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,70}$/")),
          "street must be at most 70 characters long"
        )
      ->concatResult(
          data
          ->valueFromJsonEntry("creditorStreetNumber")
          ->validateWithAddressType(
              creditorAddressTypeResult,
              validateWithRexp(_,
                x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,16}$/")),
                "street number must be at most 16 characters long for structured address values"
              ),
              validateWithRexp(_,
                x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0}$/")),
                "street number must be empty for combined address values"
              )
            )
        )
      ->validateWithPostOfficeBox(creditorPostOfficeBoxResult)
      ->entryKey("creditorAddressLine1"),

      data
      ->valueFromJsonEntry("creditorPostalCode")
      ->validateWithAddressType(
          creditorAddressTypeResult,
          validateWithRexp(_,
            x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,16}$/")),
            "postal code must be at most 16 characters long for structured address values"
          ),
          validateWithRexp(_,
            x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0}$/")),
            "postal code must be empty for combined address values"
          )
        )
      ->concatResult(
          data
          ->valueFromJsonEntry("creditorLocality")
          ->validateWithRexp(
              x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{1,35}$/")),
              "locality must not be empty and at most 35 characters long"
            )
        )
      ->entryKey("creditorAddressLine2"),

      data
      ->valueFromJsonEntry("creditorCountryCode")
      ->validateWithRexp(
          x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^\S{2}$/")),
          "must be 2 characters long"
        ),

      data
      ->valueFromJsonEntry("debtorName")
      ->validateWithRexp(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{1,70}$/")),
          "must not be empty and at most 70 characters long"
        ),

      data
      ->valueFromJsonEntry("debtorStreet")
      ->validateWithRexp(
          x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,70}$/")),
          "street must be at most 70 characters long"
        )
      ->concatResult(
          data
          ->valueFromJsonEntry("debtorStreetNumber")
          ->validateWithAddressType(
              debtorAddressTypeResult,
              validateWithRexp(_,
                x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,16}$/")),
                "street number must be at most 16 characters long for structured address values"
              ),
              validateWithRexp(_,
                x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0}$/")),
                "street number must be empty for combined address values"
              )
            )
        )
      ->validateWithPostOfficeBox(debtorPostOfficeBoxResult)
      ->entryKey("debtorAddressLine1"),

      data
      ->valueFromJsonEntry("debtorPostalCode")
      ->validateWithAddressType(
          debtorAddressTypeResult,
          validateWithRexp(_,
            x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0,16}$/")),
            "postal code must be at most 16 characters long for structured address values"
          ),
          validateWithRexp(_,
            x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{0}$/")),
            "postal code must be empty for combined address values"
          )
        )
      ->concatResult(
          data
          ->valueFromJsonEntry("debtorLocality")
          ->validateWithRexp(
              x => Js.String2.trim(x)->Js.String2.match_(%re("/^[\s\S]{1,35}$/")),
              "locality must not be empty and at most 35 characters long"
            )
        )
      ->entryKey("debtorAddressLine2"),

      data
      ->valueFromJsonEntry("debtorCountryCode")
      ->validateWithRexp(
          x => Formatter.removeWhitespace(x)->Js.String2.match_(%re("/^\S{2}$/")),
          "must be 2 characters long"
        )
    ]
    ->Js.Array2.map(
        x =>
        switch x {
        | Ok(_) => x
        | Error(err) =>
          Js.log(err.key++ " " ++Js.Array2.joinWith(err.msg, " and "))
          x
        }
        ->entryFromValidationResult
      )
  }