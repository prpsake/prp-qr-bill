type dataOptionVal<'a> = { key: string, val: 'a }



type dataOption<'a> =
  | User(dataOptionVal<'a>)
  | Default(dataOptionVal<'a>)
  | Error({
      @as("type") _type: string,
      key: string,
      val: string,
      msg: string
    })
  | None



type addressData = {
  addressType: dataOption<string>,
  name: dataOption<string>,
  street: dataOption<string>,
  streetNumber: dataOption<string>,
  postOfficeBox: dataOption<string>,
  postalCode: dataOption<string>,
  locality: dataOption<string>,
  countryCode: dataOption<string>
}



type data = {
  lang: dataOption<string>,
  currency: dataOption<string>,
  amount: dataOption<string>,
  iban: dataOption<string>,
  referenceType: dataOption<string>,
  reference: dataOption<string>,
  message: dataOption<string>,
  messageCode: dataOption<string>,
  creditor: dataOption<addressData>,
  debtor: dataOption<addressData>
}



let defaultData: data = {
  lang: Default({ key: "lang", val: "en" }),
  currency: None,
  amount: None,
  iban: None,
  referenceType: Default({ key: "referenceType", val: "NON" }),
  reference: None,
  message: None,
  messageCode: None,
  creditor: None,
  debtor: None
}



let dictGet: Js.Dict.t<Js.Json.t> => string => dataOption<'a> =
  d =>
  key =>
  switch Js.Dict.get(d, key) {
  | Some(val) => User({ key, val })
  | None => None
  }



let parseString: dataOption<Js.Json.t> => dataOption<string> => dataOption<string> =
  o =>
  dfo =>
  switch o {
  | User({ key, val }) =>
    switch Js.Json.classify(val) {
    | JSONString(s) =>
      switch Js.String.trim(s) {
      | "" => dfo
      | _ => User({ key, val: s })  
      }
    | JSONNumber(n) => User({ key, val: Js.Float.toString(n) })
    | _ => dfo
    }
  | _ => dfo
  }



let parseFloatString: dataOption<Js.Json.t> => dataOption<string> => dataOption<string> =
  o =>
  dfo =>
  switch o {
  | User({ key, val }) =>
    switch Js.Json.classify(val) {
    | JSONString(s) =>
      switch Js.String.trim(s) {
      | "" => dfo
      | _ =>
        Js.Float.fromString(s)
        ->n => 
          Js.Float.isNaN(n) ? 
          dfo 
          : 
          User({ key, val: s })
      }
    | JSONNumber(n) => User({ key, val: Js.Float.toString(n) })
    | _ => dfo
    }
  | _ => dfo
  }



let chooseReferenceType =
  reference =>
  iban =>
  switch reference {
  | None => defaultData.referenceType
  | _ =>
    switch iban {
    | User({ key, val }) =>
      Formatter.removeWhitespace(val)
      ->Js.String2.substring(~from=4, ~to_=5)
      ->x => (x == "3" ? "QRR" : "SCOR")
      ->x => User({ key, val: x })
    | _ => defaultData.referenceType
    }
  }



let parseJson: string => data =
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
      let iban = dataGet("iban")->parseString(defaultData.iban)
      let reference = dataGet("reference")->parseString(defaultData.reference)
      {
        lang: dataGet("lang")->parseString(defaultData.lang),
        currency: dataGet("currency")->parseString(defaultData.currency),
        amount: dataGet("amount")->parseFloatString(defaultData.amount),
        iban,
        referenceType: chooseReferenceType(reference, iban),
        reference,
        message: dataGet("message")->parseString(defaultData.message),
        messageCode: dataGet("messageCode")->parseString(defaultData.messageCode),
        creditor:
          switch Js.Dict.get(d, "creditor") {
          | Some(x) =>
            switch Js.Json.classify(x) {
            | JSONObject(d) =>
              let addressDataGet = dictGet(d)
              User({ 
                key: "creditor", 
                val: {
                  addressType: None,
                  name: addressDataGet("name")->parseString(None),
                  street: addressDataGet("street")->parseString(None),
                  streetNumber: addressDataGet("streetNumber")->parseString(None),
                  postOfficeBox: addressDataGet("postOfficeBox")->parseString(None),
                  postalCode: addressDataGet("postalCode")->parseString(None),
                  locality: addressDataGet("locality")->parseString(None),
                  countryCode: addressDataGet("countryCode")->parseString(None)
                }
              })
            | _ => defaultData.creditor
            }
          | None => defaultData.creditor
          },
        debtor:
          switch Js.Dict.get(d, "debtor") {
          | Some(x) =>
            switch Js.Json.classify(x) {
            | JSONObject(d) =>
              let addressDataGet = dictGet(d)
              User({ 
                key: "debtor", 
                val: {
                  addressType: None,
                  name: addressDataGet("name")->parseString(None),
                  street: addressDataGet("street")->parseString(None),
                  streetNumber: addressDataGet("streetNumber")->parseString(None),
                  postOfficeBox: addressDataGet("postOfficeBox")->parseString(None),
                  postalCode: addressDataGet("postalCode")->parseString(None),
                  locality: addressDataGet("locality")->parseString(None),
                  countryCode: addressDataGet("countryCode")->parseString(None)
                }
              })
            | _ => defaultData.debtor
            }
          | None => defaultData.debtor
          },
      }
    | _ => defaultData //failwith("Expected an object")
    }
  } catch {
  | _ => defaultData
  }