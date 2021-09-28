/*

Links:
https://www.paymentstandards.ch/dam/downloads/ig-qr-bill-en.pdf#page=28

*/



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



// Cdtr, UltmtDbtr

type addressType = [#S | #K]



type address = {
  addressType: addressType,
  name: string,
  streetOrAddressLine1: string,
  plotOrAddressLine2: string,
  postcode: string,
  locality: string,
  countrycode: string,
}


// UltmtCdtr (use type address when used in future)
type ultimateCreditorAddress = {
  addressType: string,
  name: string,
  streetOrAddressLine1: string,
  plotOrAddressLine2: string,
  postcode: string,
  locality: string,
  countrycode: string,
}


let ultimateCreditorEmpty: ultimateCreditorAddress = {
  addressType: "",
  name: "",
  streetOrAddressLine1: "",
  plotOrAddressLine2: "",
  postcode: "",
  locality: "",
  countrycode: "",
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



// QR Code Data

type qrCodeData = {
  header: header,
  creditorInfo: creditorInfo,
  creditor: address,
  ultimateCreditor: address,
  money: money,
  ultimateDebtor: address,
  referenceInfo: reference,
  additionalInfo: additionalInfo,
  alternativeInfo: alternativeInfo,
}



type validationError<'a> =
  {
    subject: string,
    message: string,
    value: 'a,
    displayValue: string
  }



type validationResult<'a> = 
  | Ok(string)
  | Error(validationError<'a>)




let valueFromValidationResult: validationResult<'a> => 'b =
  x =>
  switch x {
  | Ok(x) => x
  | Error(err) => err.displayValue
  }



// TODO: make this more generic:
// - param predicate function
// - param error record
// - return x or err displayValue (string)
let validString:
  (
    ~subject: string,
    ~matchFn: (string => option<array<string>>),
    ~message: string,
    ~displayValue: string,
    string
  ) => string =
  (
    ~subject: string,
    ~matchFn: (string => option<array<string>>),
    ~message: string,
    ~displayValue: string,
    x: string
  ) =>
  switch Js.Types.classify(x) {
  | JSString(x) => 
    switch matchFn(x) {
    | Some(match) => Ok(match[0])
    | None => Error({
        subject,
        message,
        value: x,
        displayValue
      })
    }
  | _ => 
    Error({
      subject,
      message: "is not a string",
      value: x,
      displayValue: ""
    })
  }
  -> valueFromValidationResult



let removeWhitespace: string => string =
  Js.String.replaceByRe(%re("/\s/g"), "")



let validate: qrCodeData => array<string> =
  d => {
    open Js.String2
    [
      (header.qrType :> string),
      (header.version :> string),
      Js.Int.toString((header.encoding :> int)),
      validString(
        ~subject="creditorInfo.iban",
        ~matchFn= x => removeWhitespace(x) -> match_(%re("/^(CH|LI)[0-9]{19}$/")), 
        ~message="must start with countrycode CH or LI followed by 19 digits (ex. CH1234567890123456789)",
        ~displayValue="",
        d.creditorInfo.iban
      ),
      validString(
        ~subject="creditor.addressType",
        ~matchFn= x => removeWhitespace(x) -> match_(%re("/^(K|S){1}$/")), 
        ~message="must be either K or S",
        ~displayValue="",
        (d.creditor.addressType :> string)
      ),
      validString(
        ~subject="creditor.name",
        ~matchFn= x => trim(x) -> match_(%re("/^[\s\S]{1,70}$/")), 
        ~message="must not be empty and at most 70 characters long",
        ~displayValue="",
        d.creditor.name
      )
    ]
  }



let toString: qrCodeData => string = 
  d =>
  Js.Array2.joinWith(
    [
      (d.header.qrType :> string)
    , (d.header.version :> string)
    , Js.Int.toString((d.header.encoding :> int))

    , d.creditorInfo.iban

    , (d.creditor.addressType :> string)
    , d.creditor.name
    , d.creditor.streetOrAddressLine1
    , d.creditor.plotOrAddressLine2
    , d.creditor.postcode
    , d.creditor.locality
    , d.creditor.countrycode

    , (d.ultimateCreditor.addressType :> string)
    , d.ultimateCreditor.name
    , d.ultimateCreditor.streetOrAddressLine1
    , d.ultimateCreditor.plotOrAddressLine2
    , d.ultimateCreditor.postcode
    , d.ultimateCreditor.locality
    , d.ultimateCreditor.countrycode

    , Js.Float.toString((d.money.amount :> float))
    , (d.money.currency :> string)

    , (d.ultimateDebtor.addressType :> string)
    , d.ultimateDebtor.name
    , d.ultimateDebtor.streetOrAddressLine1
    , d.ultimateDebtor.plotOrAddressLine2
    , d.ultimateDebtor.postcode
    , d.ultimateDebtor.locality
    , d.ultimateDebtor.countrycode

    , (d.referenceInfo.referenceType :> string)
    , d.referenceInfo.referenceCode

    , d.additionalInfo.unstructured
    , (d.additionalInfo.trailer :> string)
    , d.additionalInfo.structured

    , d.alternativeInfo.paramLine1
    , d.alternativeInfo.paramLine2
    ],
    "\n",
  )