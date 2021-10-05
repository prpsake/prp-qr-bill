module type Parser = {

  let parseJson: string => Js.Dict.t<Js.Json.t>

}


module Parser: Parser = {

  type entry = (string, Js.Json.t)



  let defaultRootEntries: array<entry> = {
    open Js.Json
    [
      ("lang", string("en")),
      ("currency", string("")),
      ("amount", string("")),
      ("iban", string("")),
      ("reference", string(""))
    ]
  }



  let defaultAddressEntries: array<entry> = {
    open Js.Json
    [
      ("name", string("")),
      ("street", string("")),
      ("streetNumber", string("")),
      ("postOfficeBox", string("")),
      ("postalCode", string("")),
      ("locality", string("")),
      ("countryCode", string(""))
    ]
  }



  let defaultAdditionalInfoEntries: array<entry> = {
    open Js.Json
    [
      ("message", string("")),
      ("code", string(""))
    ]
  }



  let defaultEntries: array<entry> = {
    open Js.Json
    defaultRootEntries
    -> Js.Array2.concat([
      ("creditor", object_(Js.Dict.fromArray(defaultAddressEntries))),
      ("debtor", object_(Js.Dict.fromArray(defaultAddressEntries))),
      ("additionalInfo", object_(Js.Dict.fromArray(defaultAdditionalInfoEntries)))
    ])
  }



  let entryFromData: Js.Dict.t<Js.Json.t> => entry => entry =
    data =>
    ((k, v)) =>
    switch Js.Dict.get(data, k) {
    | Some(x) =>
      switch Js.Json.classify(x) {
      | Js.Json.JSONString(x) => (k, Js.Json.string(x))
      | _ => (k, v)
      }
    | None => (k, v)
    }



  let entriesFromNestedData: string => array<entry> => Js.Dict.t<Js.Json.t> => array<entry> =
    key =>
    defaultNestedEntries =>
    data =>
    [(
      key,
      switch Js.Dict.get(data, key) {
      | Some(x) =>
        switch Js.Json.classify(x) {
        | Js.Json.JSONObject(nestedData) =>
          Js.Array2.map(defaultNestedEntries, entryFromData(nestedData))
        | _ => defaultNestedEntries
        }
      | None => defaultNestedEntries
      }
      -> Js.Dict.fromArray
      -> Js.Json.object_
    )]



  let parseJson: string => Js.Dict.t<Js.Json.t> =
    str => {
      let json = 
        try Js.Json.parseExn(str)
        catch {
        | _ => 
          defaultEntries
          -> Js.Dict.fromArray
          -> Js.Json.object_
        }
      switch Js.Json.classify(json) {
      | Js.Json.JSONObject(data) =>
        defaultRootEntries
        -> Js.Array2.map(entryFromData(data))
        -> Js.Array2.concat(entriesFromNestedData("creditor", defaultAddressEntries, data))
        -> Js.Array2.concat(entriesFromNestedData("debtor", defaultAddressEntries, data))
        -> Js.Array2.concat(entriesFromNestedData("additionalInfo", defaultAdditionalInfoEntries, data))
      | _ => defaultEntries //failwith("Expected an object")
      }
      -> Js.Dict.fromArray
    }

}

