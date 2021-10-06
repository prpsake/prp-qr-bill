module type Formatter = {

  let blockStr3: string => string
  let blockStr4: string => string
  let blockStr5: string => string
  let referenceBlockStr: string => string
  let moneyFromScaledIntStr2: string => string

}



module Formatter: Formatter = {

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

  


  /** 

  `reverseStr(x)` 

  Takes string `x` and returns a reversed string from `x`.
  
  */
  let reverseStr: string => string =
    x =>
    Js.String2.split(x, "")
    -> Js.Array2.reverseInPlace
    -> Js.Array2.joinWith("")



  /**

  `blockStr(n, x)`

  Takes integer `n`, string `x` and returns a string from `x` grouped in 
  character-blocks of length `n` seperated by spaces.

  Examples: 
  - n = 3, x = "123456789" -> "123 456 789"
  - n = 4, x = "abcdefgh" -> "abcd efgh"

  */
  let blockStr: int => string => string =
    n =>
    x =>
    switch Js.Types.classify(x) {
    | JSString(x) => 
      let x_ = Js.String2.replaceByRe(x, %re("/\s/g"), "")
      let pat = Js.Re.fromStringWithFlags("\\S{"++ Belt.Int.toString(n) ++"}", ~flags="g")
      Js.String2.replaceByRe(x_, pat, "$& ")
    | _ => ""
    }


  
  let blockStr3 = blockStr(3)
  let blockStr4 = blockStr(3)
  let blockStr5 = blockStr(5)



  /**

  referenceBlockStr(x)

  Takes string `x`, if `x` starts with "RF", returns a string from `x` in 
  the Creditor Reference format (CROOKS 11649), else returns a string from `x` 
  in the QR-Reference format.

  Examples:
  - x = "RF18539007547034" -> "RF18 5390 0754 7034"
  - x = "213455654786322980076652786" -> "21 34556 54786 32298 00766 52786"

  */
  let referenceBlockStr: string => string =
    x =>
    switch Js.Types.classify(x) {
    | JSString(x) =>
      let xTrim = Js.String2.trim(x)
      switch Js.String2.startsWith(xTrim, "RF") {
      | true => blockStr4(xTrim)
      | false => 
        let head = Js.String2.substring(xTrim, ~from=0, ~to_=2)
        let tail = blockStr5(Js.String2.substringToEnd(xTrim, ~from=2))
        head++ " " ++tail
      }
    | _ => ""
    }



  /**

  moneyFromScaledIntStr(n, x)

  Takes integer `n`, string `x` and returns a string from `x`

  */
  let moneyFromScaledIntStr: int => string => string =
    n =>
    x =>
    switch Js.Types.classify(x) {
    | JSString(x) =>
      let xTrim = Js.String2.trim(x)
      xTrim
      -> Js.String2.slice(~from=0, ~to_=-n)
      -> reverseStr
      -> blockStr3
      -> reverseStr
      ++ "." 
      ++ Js.String2.sliceToEnd(xTrim, ~from=-n)
    | _ => ""
    }



  let moneyFromScaledIntStr2 = moneyFromScaledIntStr(2)




  // let suffixEntryKeys: string => array<entry> => array<entry> =
  //   str =>
  //   xs =>
  //   Js.Array2.map(xs, ((k, v)) => {
  //     (
  //       k
  //       ++ Js.String2.substring(str, ~from=0, ~to_=1) -> Js.String2.toUpperCase
  //       ++ Js.String2.sliceToEnd(str, ~from=1),
  //       v
  //     )
  //   })

}