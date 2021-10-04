let defaultAddressData = {
  open Js.Json
  Js.Dict.fromArray([
    ("name", string("")),
    ("street", string("")),
    ("streetNumber", string("")),
    ("postOfficeBox", string("")),
    ("postalCode", string("")),
    ("locality", string("")),
    ("countryCode", string(""))
  ])
}



let defaultAdditionalInfoData = {
  open Js.Json
  Js.Dict.fromArray([
    ("message", string("")),
    ("code", string(""))
  ])
}



let defaultData = {
  open Js.Json
  Js.Dict.fromArray([
    ("lang", string("en")),
    ("currency", string("")),
    ("amount", string("")),
    ("iban", string("")),
    ("reference", string("")),
    ("creditor", object_(defaultAddressData)),
    ("debtor", object_(defaultAddressData)),
    ("additionalInfo", object_(defaultAdditionalInfoData))
  ])
}



let getJsonString: Js.Dict.t<'a> => Js.Dict.t<'a> => string => Js.Json.t =
  defaultData =>
  data =>
  key =>
  switch Js.Dict.get(data, key) {
  | Some(x) =>
    switch Js.Json.classify(x) {
    | Js.Json.JSONString(x) => x
    | Js.Json.JSONNumber(x) => Belt.Float.toString(x)
    | _ =>
      switch Js.Dict.get(defaultData, key) {
      | Some(x) =>
        switch Js.Json.classify(x) {
        | Js.Json.JSONString(x) => x
        | _ => ""
        }
      | None => ""
      }
    }
  | None =>
    switch Js.Dict.get(defaultData, key) {
    | Some(x) =>
      switch Js.Json.classify(x) {
      | Js.Json.JSONString(x) => x
      | _ => ""
      }
    | None => ""
    }
  }
  -> Js.Json.string



let parseJson =
  str => {
    let json = 
      try Js.Json.parseExn(str)
      catch {
      | _ => Js.Json.object_(defaultData)
      }
    switch Js.Json.classify(json) {
    | Js.Json.JSONObject(data) =>
      let withKey = getJsonString(defaultData, data)
      let withAddressDataAndKey = getJsonString(defaultAddressData)
      let withAdditionalInfoDataAndKey = getJsonString(defaultAdditionalInfoData)
      Js.Dict.fromArray([
        ("lang",      withKey("lang")),
        ("currency",  withKey("currency")),
        ("amount",    withKey("amount")),
        ("iban",      withKey("iban")),
        ("reference", withKey("reference")),
        ("creditor",
          switch Js.Dict.get(data, "creditor") {
          | Some(json) =>
            switch Js.Json.classify(json) {
            | Js.Json.JSONObject(addressData) =>
              Js.Dict.fromArray([
                ("name",          withAddressDataAndKey(addressData, "name")),
                ("street",        withAddressDataAndKey(addressData, "street")),
                ("streetNumber",  withAddressDataAndKey(addressData, "streetNumber")),
                ("postOfficeBox", withAddressDataAndKey(addressData, "postOfficeBox")),
                ("postalCode",    withAddressDataAndKey(addressData, "postalCode")),
                ("locality",      withAddressDataAndKey(addressData, "locality")),
                ("countryCode",   withAddressDataAndKey(addressData, "countryCode"))
              ])
            | _ => defaultAddressData
            }
          | None => defaultAddressData
          }
          -> Js.Json.object_
        ),
        ("debtor",
          switch Js.Dict.get(data, "debtor") {
          | Some(json) =>
            switch Js.Json.classify(json) {
            | Js.Json.JSONObject(addressData) =>
              Js.Dict.fromArray([
                ("name",          withAddressDataAndKey(addressData, "name")),
                ("street",        withAddressDataAndKey(addressData, "street")),
                ("streetNumber",  withAddressDataAndKey(addressData, "streetNumber")),
                ("postOfficeBox", withAddressDataAndKey(addressData, "postOfficeBox")),
                ("postalCode",    withAddressDataAndKey(addressData, "postalCode")),
                ("locality",      withAddressDataAndKey(addressData, "locality")),
                ("countryCode",   withAddressDataAndKey(addressData, "countryCode"))
              ])
            | _ => defaultAddressData
            }
          | None => defaultAddressData
          }
          -> Js.Json.object_
        ),
        ("additionalInfo",
          switch Js.Dict.get(data, "additionalInfo") {
          | Some(json) =>
            switch Js.Json.classify(json) {
            | Js.Json.JSONObject(additionalInfoData) =>
              Js.Dict.fromArray([
                ("message", withAdditionalInfoDataAndKey(additionalInfoData, "message")),
                ("code",    withAdditionalInfoDataAndKey(additionalInfoData, "code"))
              ])
            | _ => defaultAdditionalInfoData
            }
          | None => defaultAdditionalInfoData
          } 
          -> Js.Json.object_
        )
      ])
    | _ => failwith("Expected an object")
    }
  }
