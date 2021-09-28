/*

Links:
https://www.paymentstandards.ch/dam/downloads/ig-qr-bill-en.pdf#page=28

*/

// Header

type qrType = [#SPC]
type version = [#"0200"]
type coding = [#1]

type header = {
  qrType: qrType, // QRType
  version: version, // Version
  encoding: coding, // Coding
}

let headerV0200: header = {
  qrType: #SPC,
  version: #"0200",
  encoding: #1,
}

// CdtrInf

type creditorInfo = {iban: string}

// Cdtr, UltmtCdtr (for future use), UltmtDbtr

type addressType = [#S | #K | #EMPTY]

type address = {
  addressType: addressType,
  name: string,
  streetOrAddressLine1: string,
  plotOrAddressLine2: string,
  postcode: string,
  locality: string,
  countrycode: string,
}

let ultimateCreditorEmpty: address = {
  addressType: #EMPTY,
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

let toString: qrCodeData => string = d =>
  Js.Array2.joinWith(
    [
      (d.header.qrType :> string),
      (d.header.version :> string),
      Js.Int.toString((d.header.encoding :> int)),
      d.creditorInfo.iban,
      (d.creditor.addressType :> string),
      d.creditor.name,
      d.creditor.streetOrAddressLine1,
      d.creditor.plotOrAddressLine2,
      d.creditor.postcode,
      d.creditor.locality,
      d.creditor.countrycode,
      (d.ultimateCreditor.addressType :> string),
      d.ultimateCreditor.name,
      d.ultimateCreditor.streetOrAddressLine1,
      d.ultimateCreditor.plotOrAddressLine2,
      d.ultimateCreditor.postcode,
      d.ultimateCreditor.locality,
      d.ultimateCreditor.countrycode,
      Js.Float.toString((d.money.amount :> float)),
      (d.money.currency :> string),
      (d.ultimateDebtor.addressType :> string),
      d.ultimateDebtor.name,
      d.ultimateDebtor.streetOrAddressLine1,
      d.ultimateDebtor.plotOrAddressLine2,
      d.ultimateDebtor.postcode,
      d.ultimateDebtor.locality,
      d.ultimateDebtor.countrycode,
      (d.referenceInfo.referenceType :> string),
      d.referenceInfo.referenceCode,
      d.additionalInfo.unstructured,
      (d.additionalInfo.trailer :> string),
      d.additionalInfo.structured,
      d.alternativeInfo.paramLine1,
      d.alternativeInfo.paramLine2,
    ],
    "\n",
  )