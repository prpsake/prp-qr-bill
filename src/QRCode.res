/*

Links:
https://www.paymentstandards.ch/dam/downloads/ig-qr-bill-en.pdf#page=28
https://regex101.com/

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



type entry = (string, string)



let join: array<string> => string =
  values =>
  Js.Array2.joinWith(values, " ")
  ->Js.String2.trim



let valueFromEntry: Js.Dict.t<string> => string => string =
  data =>
  key =>
  switch Js.Dict.get(data, key) {
  | Some(x) => x
  | None => ""
  }



let qrCodeString: array<entry> => string =
  entries => {
    let data = Js.Dict.fromArray(entries)
    [
      data->valueFromEntry("iban"),
      data->valueFromEntry("creditorAddresstype"),
      data->valueFromEntry("creditorName"),
      join([
        data->valueFromEntry("creditorStreet"),
        data->valueFromEntry("creditorStreetNumber")
      ]),
      join([
        data->valueFromEntry("creditorPostalCode"),
        data->valueFromEntry("creditorLocality")
      ])
  
    ]
    ->Js.Array2.joinWith("\n")
  }
