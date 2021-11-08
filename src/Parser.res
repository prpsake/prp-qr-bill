let dictGet: Js.Dict.t<Js.Json.t> => string => Data.dataOption<'a> =
  d =>
  key =>
  switch Js.Dict.get(d, key) {
  | Some(val) => Data.User({ key, val })
  | None => Data.None
  }



let parseString: Data.dataOption<Js.Json.t> => Data.dataOption<string> => Data.dataOption<string> =
  o =>
  dfo =>
  switch o {
  | Data.User({ key, val }) =>
    switch Js.Json.classify(val) {
    | JSONString(s) =>
      switch Js.String.trim(s) {
      | "" => dfo
      | _ => Data.User({ key, val: s })  
      }
    | JSONNumber(n) => Data.User({ key, val: Js.Float.toString(n) })
    | _ => dfo
    }
  | _ => dfo
  }



let parseFloatString: Data.dataOption<Js.Json.t> => Data.dataOption<string> => Data.dataOption<string> =
  o =>
  dfo =>
  switch o {
  | Data.User({ key, val }) =>
    switch Js.Json.classify(val) {
    | JSONString(s) =>
      switch Js.String.trim(s) {
      | "" => dfo
      | _ =>
        Js.Float.fromString(s)
        ->n => Js.Float.isNaN(n) ? dfo : Data.User({ key, val: s })
      }
    | JSONNumber(n) => Data.User({ key, val: Js.Float.toString(n) })
    | _ => dfo
    }
  | _ => dfo
  }



let chooseReferenceType =
  reference =>
  iban =>
  switch reference {
  | Data.None => Data.defaultData.referenceType
  | _ =>
    switch iban {
    | Data.User({ val }) =>
      Formatter.removeWhitespace(val)
      ->Js.String2.substring(~from=4, ~to_=5)
      ->x => (x == "3" ? "QRR" : "SCOR")
      ->x => Data.User({ key: "referenceType", val: x })
    | _ => Data.defaultData.referenceType
    }
  }



let chooseAddressType =
  streetNumber =>
  postalCode =>
  (streetNumber === Data.None || postalCode === Data.None ? "K" : "S")
  ->val => Data.User({ key: "addressType", val })



let parseJson: string => Data.data =
  str =>
  try {
    let json =
      switch Js.Json.stringifyAny(str) {
      | Some(x) => x
      | None => ""
      }
      ->Js.Json.parseExn
    switch Js.Json.classify(json) {
    | JSONObject(d) =>
      let dataGet = dictGet(d)
      let iban = dataGet("iban")->parseString(Data.defaultData.iban)
      let reference = dataGet("reference")->parseString(Data.defaultData.reference)
      {
        lang: dataGet("lang")->parseString(Data.defaultData.lang),
        currency: dataGet("currency")->parseString(Data.defaultData.currency),
        amount: dataGet("amount")->parseFloatString(Data.defaultData.amount),
        iban,
        referenceType: chooseReferenceType(reference, iban),
        reference,
        message: dataGet("message")->parseString(Data.defaultData.message),
        messageCode: dataGet("messageCode")->parseString(Data.defaultData.messageCode),
        creditor:
          switch Js.Dict.get(d, "creditor") {
          | Some(x) =>
            switch Js.Json.classify(x) {
            | JSONObject(d) =>
              let addressDataGet = dictGet(d)
              let streetNumber = addressDataGet("streetNumber")->parseString(Data.None)
              let postalCode = addressDataGet("postalCode")->parseString(Data.None)
              Data.User({ 
                key: "creditor", 
                val: {
                  addressType: chooseAddressType(streetNumber, postalCode),
                  name: addressDataGet("name")->parseString(Data.None),
                  street: addressDataGet("street")->parseString(Data.None),
                  streetNumber,
                  postOfficeBox: addressDataGet("postOfficeBox")->parseString(Data.None),
                  postalCode,
                  locality: addressDataGet("locality")->parseString(Data.None),
                  countryCode: addressDataGet("countryCode")->parseString(Data.None)
                }
              })
            | _ => Data.defaultData.creditor
            }
          | None => Data.defaultData.creditor
          },
        debtor:
          switch Js.Dict.get(d, "debtor") {
          | Some(x) =>
            switch Js.Json.classify(x) {
            | JSONObject(d) =>
              let addressDataGet = dictGet(d)
              let streetNumber = addressDataGet("streetNumber")->parseString(Data.None)
              let postalCode = addressDataGet("postalCode")->parseString(Data.None)
              Data.User({ 
                key: "debtor", 
                val: {
                  addressType: chooseAddressType(streetNumber, postalCode),
                  name: addressDataGet("name")->parseString(Data.None),
                  street: addressDataGet("street")->parseString(Data.None),
                  streetNumber,
                  postOfficeBox: addressDataGet("postOfficeBox")->parseString(Data.None),
                  postalCode,
                  locality: addressDataGet("locality")->parseString(Data.None),
                  countryCode: addressDataGet("countryCode")->parseString(Data.None)
                }
              })
            | _ => Data.defaultData.debtor
            }
          | None => Data.defaultData.debtor
          },
      }
    | _ => Data.defaultData //failwith("Expected an object")
    }
  } catch {
  | _ => Data.defaultData
  }