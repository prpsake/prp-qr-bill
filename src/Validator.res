/*

Links:
https://www.paymentstandards.ch/dam/downloads/ig-qr-bill-en.pdf#page=28
https://regex101.com/

*/


type entry = (string, Js.Json.t)



type validationError<'a> =
  {
    key: string,
    msg: array<string>,
    val: 'a,
    display: string
  }



type validationResult<'a> = 
  | Ok(string)
  | Error(validationError<'a>)



let mod97FromIban: string => int =
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



let validateEntry:
  (
    Js.Dict.t<Js.Json.t>,
    string,
    ~fn: (string => option<array<string>>),
    ~msg: string,
    ~display: string,
  ) => validationResult<'a> =
  (
    data: Js.Dict.t<Js.Json.t>,
    key: string,
    ~fn: (string => option<array<string>>),
    ~msg: string,
    ~display: string,
  ) =>
  switch Js.Dict.get(data, key) {
  | Some(x) => 
    switch Js.Json.classify(x) {
    | JSONString(x) => 
      switch fn(x) {
      | Some(xs) => Ok(xs[0])
      | None =>
        Error({key, msg: [msg], val: x, display })
      }
    | _ => 
      Error({key, msg: ["is not a string"], val: "", display: "" })
    }
  | None =>
    Error({key, msg: ["is not a string"], val: "", display: "" })
  }



let validateIban: validationResult<'a> => validationResult<'a> =
  result =>
  switch result {
  | Ok(str) => {
    let codeA = Js.String2.charCodeAt(`A`, 0)
    let codeZ = Js.String2.charCodeAt(`Z`, 0)
    str
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
    ->mod97FromIban
    ->x =>
      x == 1 ? Ok(str) : Error({
        key: "iban",
        msg: ["fails the checksum"],
        val: str,
        display: ""
      })
    }
  | Error(err) => Error(err)
  }




let entryFromValidationResult: validationResult<'a> => string => entry =
  x =>
  key =>
  switch x {
  | Ok(x) => (key, Js.Json.string(x))
  | Error(err) => (key, Js.Json.string(err.display))
  }



let validateEntries: array<entry> => array<entry> =
  entries => {
    let data = Js.Dict.fromArray(entries)
    [
      data
      ->validateEntry(
          "lang",
          ~fn= 
            x => Formatter.removeWhitespace(x) ->Js.String2.match_(%re("/^(en|de|fr|it)$/")), 
          ~msg="must be either en, de, fr, or it",
          ~display=""
        )
      ->entryFromValidationResult("lang"),

      data
      ->validateEntry(
          "currency",
          ~fn= x => Formatter.removeWhitespace(x) ->Js.String2.match_(%re("/^(CHF|EUR)$/")), 
          ~msg="must be either CHF or EUR",
          ~display=""
        )
      ->entryFromValidationResult("currency"),

      data
      ->validateEntry(
          "amount",
          ~fn= 
            x => 
            Formatter.removeWhitespace(x)
            ->Js.Float.fromString
            ->Js.Float.toFixedWithPrecision(~digits=2)
            ->Js.String2.match_(%re("/^([1-9]{1}[0-9]{0,8}\.[0-9]{2}|0\.[0-9]{1}[1-9]{1})$/")), 
          ~msg="must be a number ranging from 0.01 to 999999999.99",
          ~display=""
        )
      ->entryFromValidationResult("amount"),

      data
      ->validateEntry(
          "iban",
          ~fn= 
            x => 
            Formatter.removeWhitespace(x)
            ->Js.String2.toUpperCase
            ->Js.String2.match_(%re("/^(CH|LI)[0-9]{19}$/")), 
          ~msg="must start with countryCode CH or LI followed by 19 digits (ex. CH1234567890123456789)",
          ~display=""
        )
      ->validateIban
      ->entryFromValidationResult("iban"),

      data
      ->validateEntry(
          "referenceType",
          ~fn= x => Formatter.removeWhitespace(x) ->Js.String2.match_(%re("/^(QRR|SCOR|NON)$/")), 
          ~msg="must be either QRR, SCOR or NON",
          ~display=""
        )
      ->entryFromValidationResult("referenceType"),

      data
      ->validateEntry(
          "reference",
          ~fn= x => Formatter.removeWhitespace(x) ->Js.String2.match_(%re("/^[\s\S]{0,27}$/")), 
          ~msg="must be at most 27 characters long",
          ~display=""
        )
      ->entryFromValidationResult("reference"),

      data
      ->validateEntry(
          "message",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^[\s\S]{0,140}$/")),
          ~msg="must be at most 140 characters long",
          ~display=""
        )
      ->entryFromValidationResult("message"),

      data
      ->validateEntry(
          "messageCode",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^[\s\S]{0,140}$/")),
          ~msg="must be at most 140 characters long",
          ~display=""
        )
      ->entryFromValidationResult("messageCode"),

      data
      ->validateEntry(
          "creditorAddressType",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^(K|S){1}$/")), 
          ~msg="must be either K or S",
          ~display="",
        )
      ->entryFromValidationResult("creditorAddressType"),

      data
      ->validateEntry(
          "creditorName",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^[\s\S]{1,70}$/")),
          ~msg="must not be empty and at most 70 characters long",
          ~display=""
        )
      ->entryFromValidationResult("creditorName"),

      data
      ->validateEntry(
          "creditorStreet",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^[\s\S]{0,70}$/")),
          ~msg="must be at most 70 characters long",
          ~display=""
        )
      ->entryFromValidationResult("creditorStreet"),

      data
      ->validateEntry(
          "creditorStreetNumber",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^[\s\S]{0,16}$/")),
          ~msg="must be at most 16 characters long",
          ~display=""
        )
      ->entryFromValidationResult("creditorStreetNumber"),

      data
      ->validateEntry(
          "creditorPostOfficeBox",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^[\s\S]{0,70}$/")),
          ~msg="must be at most 70 characters long",
          ~display=""
        )
      ->entryFromValidationResult("creditorPostOfficeBox"),

      data
      ->validateEntry(
          "creditorPostalCode",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^[\s\S]{0,16}$/")),
          ~msg="must be at most 16 characters long",
          ~display=""
        )
      ->entryFromValidationResult("creditorPostalCode"),

      data
      ->validateEntry(
          "creditorLocality",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^[\s\S]{1,35}$/")),
          ~msg="must not be empty and at most 35 characters long",
          ~display=""
        )
      ->entryFromValidationResult("creditorLocality"),

      data
      ->validateEntry(
          "creditorCountryCode",
          ~fn= x => Formatter.removeWhitespace(x) ->Js.String2.match_(%re("/^\S{2}$/")),
          ~msg="must be 2 characters long",
          ~display=""
        )
      ->entryFromValidationResult("creditorCountryCode"),

      data
      ->validateEntry(
          "debtorAddressType",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^(K|S){1}$/")), 
          ~msg="must be either K or S",
          ~display="",
        )
      ->entryFromValidationResult("debtorAddressType"),

      data
      ->validateEntry(
          "debtorName",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^[\s\S]{1,70}$/")),
          ~msg="must not be empty and at most 70 characters long",
          ~display=""
        )
      ->entryFromValidationResult("debtorName"),

      data
      ->validateEntry(
          "debtorStreet",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^[\s\S]{0,70}$/")),
          ~msg="must be at most 70 characters long",
          ~display=""
        )
      ->entryFromValidationResult("debtorStreet"),

      data
      ->validateEntry(
          "debtorStreetNumber",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^[\s\S]{0,16}$/")),
          ~msg="must be at most 16 characters long",
          ~display=""
        )
      ->entryFromValidationResult("debtorStreetNumber"),

      data
      ->validateEntry(
          "debtorPostOfficeBox",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^[\s\S]{0,70}$/")),
          ~msg="must be at most 70 characters long",
          ~display=""
        )
      ->entryFromValidationResult("debtorPostOfficeBox"),

      data
      ->validateEntry(
          "debtorPostalCode",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^[\s\S]{0,16}$/")),
          ~msg="must be at most 16 characters long",
          ~display=""
        )
      ->entryFromValidationResult("debtorPostalCode"),
        
      data
      ->validateEntry(
          "debtorLocality",
          ~fn= x => Js.String2.trim(x) ->Js.String2.match_(%re("/^[\s\S]{1,35}$/")),
          ~msg="must not be emtpy and at most 35 characters long",
          ~display=""
        )
      ->entryFromValidationResult("debtorLocality"),

      data
      ->validateEntry(
          "debtorCountryCode",
          ~fn= x => Formatter.removeWhitespace(x) ->Js.String2.match_(%re("/^\S{2}$/")),
          ~msg="must be 2 characters long",
          ~display=""
        )
      ->entryFromValidationResult("debtorCountryCode")
    ]
  }