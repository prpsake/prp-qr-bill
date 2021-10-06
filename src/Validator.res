/*

Links:
https://www.paymentstandards.ch/dam/downloads/ig-qr-bill-en.pdf#page=28
https://regex101.com/

*/



module type Validator = {

  type entry
  let validate: array<entry> => array<entry>
  
}



module Validator: Validator = {


  // Header

  type qrType = [#SPC]
  type version = [#"0200"]
  type encoding = [#1]


  type header = {
    qrType: qrType, // QRType
    version: version, // Version
    encoding: encoding, // Coding
  }


  let header: header = {
    qrType: #SPC,
    version: #"0200",
    encoding: #1,
  }



  // CdtrInf

  type creditorInfo = {iban: string}



  // Cdtr(, UltmtDbtr)

  type addressType = [#S | #K]


  type address = {
    addressType: addressType,
    name: string,
    streetOrAddressLine1: string,
    streetNumberOrAddressLine2: string,
    postalCode: string,
    locality: string,
    countryCode: string,
  }



  // UltmtCdtr (use type address when used in future)

  type ultimateCreditorAddress = {
    addressType: string,
    name: string,
    streetOrAddressLine1: string,
    streetNumberOrAddressLine2: string,
    postalCode: string,
    locality: string,
    countryCode: string,
  }


  let ultimateCreditorEmpty: ultimateCreditorAddress = {
    addressType: "",
    name: "",
    streetOrAddressLine1: "",
    streetNumberOrAddressLine2: "",
    postalCode: "",
    locality: "",
    countryCode: "",
  }



  // CcyAmt

  type currency = [#CHF | #EUR]


  type money = {
    amount: float,
    currency: currency,
  }



  // RmtInf

  type referenceType = [#QRR | #SCOR | #NON]


  type reference = {
    referenceType: referenceType,
    referenceCode: string,
  }



  // AddInf

  type trailer = [#EPD]


  type additionalInfo = {
    unstructured: string,
    trailer: trailer,
    structured: string,
  }



  // AltPmtInf

  type alternativeInfo = {
    paramLine1: string,
    paramLine2: string,
  }



  // QR Code Data Rec

  type qrCodeData = {
    header: header,
    creditorInfo: creditorInfo,
    creditor: address,
    ultimateCreditor: address,
    money: money,
    ultimateDebtor: ultimateCreditorAddress,
    referenceInfo: reference,
    additionalInfo: additionalInfo,
    alternativeInfo: alternativeInfo,
  }



  type entry = (string, Js.Json.t)



  type validationError<'a> =
    {
      key: string,
      message: string,
      value: 'a,
      displayValue: string
    }



  type validationResult<'a> = 
    | Ok(string)
    | Error(validationError<'a>)



  let entryFromValidationResult: validationResult<'a> => string => entry =
    x =>
    key =>
    switch x {
    | Ok(x) => (key, Js.Json.string(x))
    | Error(err) => (key, Js.Json.string(err.displayValue))
    }



  let validString:
    (
      option<Js.Json.t>,
      ~key: string,
      ~matchFn: (string => option<array<string>>),
      ~message: string,
      ~displayValue: string,
    ) => entry =
    (
      x: option<Js.Json.t>,
      ~key: string,
      ~matchFn: (string => option<array<string>>),
      ~message: string,
      ~displayValue: string,
    ) =>
    switch x {
    | Some(x) => 
      switch Js.Json.classify(x) {
      | Js.Json.JSONString(x) => 
        switch matchFn(x) {
        | Some(match) => Ok(match[0])
        | None => Error({
            key,
            message,
            value: x,
            displayValue
          })
        }
      | _ => 
        Error({
          key,
          message: "is not a string",
          value: "",
          displayValue: ""
        })
      }
    | None =>
      Error({
        key,
        message: "is not a string",
        value: "",
        displayValue: ""
      })
    }
    ->entryFromValidationResult(key)



  let removeWhitespace: string => string =
    Js.String.replaceByRe(%re("/\s/g"), "")



  let validate: array<entry> => array<entry> =
    entries => {
      let data = Js.Dict.fromArray(entries)
      [
        // (header.qrType :> string),
        // (header.version :> string),
        // Js.Int.toString((header.encoding :> int)),
        Js.Dict.get(data, "iban")
        ->validString(
          ~key="iban",
          ~matchFn= x => removeWhitespace(x) -> Js.String2.match_(%re("/^(CH|LI)[0-9]{19}$/")), 
          ~message="must start with countryCode CH or LI followed by 19 digits (ex. CH1234567890123456789)",
          ~displayValue=""
        ),
        // Js.Dict.get(data, "creditorName")
        // validString(
        //   ~key="creditor.addressType",
        //   ~matchFn= x => removeWhitespace(x) -> match_(%re("/^(K|S){1}$/")), 
        //   ~message="must be either K or S",
        //   ~displayValue="",
        //   (d.creditor.addressType :> string)
        // ),
        Js.Dict.get(data, "creditorName")
        ->validString(
          ~key="creditorName",
          ~matchFn= x => Js.String2.trim(x) -> Js.String2.match_(%re("/^[\s\S]{1,70}$/")),
          ~message="must not be empty and at most 70 characters long",
          ~displayValue=""
        ),
        // Js.Dict.get(data, "creditorStreet")
        // validString(
        //   ~key="creditor.streetOrAddressLine1",
        //   ~matchFn= x => trim(x) -> match_(%re("/^[\s\S]{0,70}$/")), 
        //   ~message="must be at most 70 characters long",
        //   ~displayValue="",
        //   d.creditor.streetOrAddressLine1
        // ),
        // validString(
        //   ~key="creditor.streetNumberOrAddressLine2",
        //   ~matchFn= x => trim(x) -> match_(%re("/^[\s\S]{0,70}$/")), 
        //   ~message="must be at most 70 characters long",
        //   ~displayValue="",
        //   d.creditor.streetNumberOrAddressLine2
        // )
      ]
    }

}