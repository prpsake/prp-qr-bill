type dataOption<'a> =
  | User({
      key: string,
      val: 'a
    })
  | Default({
      key: string,
      val: 'a
    })
  | Error({
      @as("type") _type: string,
      key: string,
      val: string,
      msg: string
    })
  | None



type appAddress = {
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
  reference: dataOption<string>,
  referenceType: dataOption<string>,
  message: dataOption<string>,
  messageCode: dataOption<string>,
  creditor: dataOption<appAddress>,
  debtor: dataOption<appAddress>
}



let defaultData: data = {
  lang: Default({ key: "lang", val: "en" }),
  currency: None,
  amount: None,
  iban: None,
  reference: None,
  referenceType: Default({ key: "referenceType", val: "NON" }),
  message: None,
  messageCode: None,
  creditor: None,
  debtor: None
}



let parseString: Js.Json.t => string => dataOption<string> => dataOption<string> =
  t =>
  key =>
  defaultDataOption =>
  switch Js.Json.classify(t) {
  | JSONString(s) =>
    switch Js.String.trim(s) {
    | "" => defaultDataOption
    | _ => User({ key, val: s }) 
    }
  | JSONNumber(n) => User({ key, val: Js.Float.toString(n) })
  | _ => defaultDataOption
  }



let parseFloatString: Js.Json.t => string => dataOption<'a> => dataOption<string> =
  t =>
  key => 
  defaultDataOption =>
  switch Js.Json.classify(t) {
  | JSONNumber(n) => User({ key, val: Js.Float.toString(n) })
  | JSONString(s) =>
    switch Js.String.trim(s) {
    | "" => defaultDataOption
    | _ =>
      Js.Float.fromString(s)
      ->n => 
        Js.Float.isNaN(n) ? 
        defaultDataOption 
        : 
        User({ key, val: s })
    }
  | _ => defaultDataOption
  }



let parseWithFn: 
  Js.Dict.t<Js.Json.t> => 
  string => 
  (Js.Json.t => string => dataOption<'a> => dataOption<'a>) => 
  dataOption<'a> => 
  dataOption<'a> 
  =
  d =>
  key =>
  fn =>
  defaultDataOption =>
  switch Js.Dict.get(d, key) {
  | Some(x) => fn(x, key, defaultDataOption)
  | None => defaultDataOption
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
      let iban = parseWithFn(d, "iban", parseString, defaultData.iban)
      let reference = parseWithFn(d, "reference", parseString, defaultData.reference)
      {
        lang: parseWithFn(d, "lang", parseString, defaultData.lang),
        currency: parseWithFn(d, "currency", parseString, defaultData.currency),
        amount: parseWithFn(d, "amount", parseFloatString, defaultData.amount),
        iban,
        reference,
        referenceType: chooseReferenceType(reference, iban),
        message: parseWithFn(d, "message", parseString, defaultData.message),
        messageCode: parseWithFn(d, "messageCode", parseString, defaultData.messageCode),
        creditor:
          switch Js.Dict.get(d, "creditor") {
          | Some(x) =>
            switch Js.Json.classify(x) {
            | JSONObject(d) =>
              User({ 
                key: "creditor", 
                val: {
                  addressType: None,
                  name: parseWithFn(d, "messageCode", parseString, None),
                  street: parseWithFn(d, "street", parseString, None),
                  streetNumber: parseWithFn(d, "streeNumber", parseString, None),
                  postOfficeBox: parseWithFn(d, "postOfficeBox", parseString, None),
                  postalCode: parseWithFn(d, "postalCode", parseString, None),
                  locality: parseWithFn(d, "locality", parseString, None),
                  countryCode: parseWithFn(d, "locality", parseString, None)
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
              User({ 
                key: "debtor", 
                val: {
                  addressType: None,
                  name: parseWithFn(d, "messageCode", parseString, None),
                  street: parseWithFn(d, "street", parseString, None),
                  streetNumber: parseWithFn(d, "streeNumber", parseString, None),
                  postOfficeBox: parseWithFn(d, "postOfficeBox", parseString, None),
                  postalCode: parseWithFn(d, "postalCode", parseString, None),
                  locality: parseWithFn(d, "locality", parseString, None),
                  countryCode: parseWithFn(d, "locality", parseString, None)
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