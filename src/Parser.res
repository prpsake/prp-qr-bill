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
    ->Js.Array2.concat([
      ("creditor", object_(Js.Dict.fromArray(defaultAddressEntries))),
      ("debtor", object_(Js.Dict.fromArray(defaultAddressEntries))),
      ("additionalInfo", object_(Js.Dict.fromArray(defaultAdditionalInfoEntries)))
    ])
  }



  let suffixEntryKeys: array<entry> => string => array<entry> =
    entries =>
    key =>
    Js.Array2.map(entries, ((k, v)) => {
      ( key
        ++Js.String2.substring(k, ~from=0, ~to_=1) ->Js.String2.toUpperCase
        ++Js.String2.sliceToEnd(k, ~from=1),
        v
      )
    })



  let entryFromData: Js.Dict.t<Js.Json.t> => entry => entry =
    data =>
    ((k, v)) =>
    switch Js.Dict.get(data, k) {
    | Some(x) =>
      switch Js.Json.classify(x) {
      | Js.Json.JSONString(x) => (k, Js.Json.string(x))
      | Js.Json.JSONNumber(x) => (k, Js.Json.string(Belt.Float.toString(x)))
      | _ => (k, v)
      }
    | None => (k, v)
    }



  let entriesFromNestedData: Js.Dict.t<Js.Json.t> => array<entry> => string => array<entry> =
    data =>
    defaultNestedEntries =>
    key =>
    switch Js.Dict.get(data, key) {
    | Some(x) =>
      switch Js.Json.classify(x) {
      | Js.Json.JSONObject(nestedData) =>
        defaultNestedEntries
        ->Js.Array2.map(entryFromData(nestedData))
      | _ => defaultNestedEntries
      }
    | None => defaultNestedEntries
    }
    ->suffixEntryKeys(key)



  let parseJson: string => Js.Dict.t<Js.Json.t> =
    str =>
    try {
      let json = Js.Json.parseExn(str)
      switch Js.Json.classify(json) {
      | Js.Json.JSONObject(data) =>
        defaultRootEntries
        ->Js.Array2.map(entryFromData(data))
        ->Js.Array2.concat(entriesFromNestedData(data, defaultAddressEntries, "creditor"))
        ->Js.Array2.concat(entriesFromNestedData(data, defaultAddressEntries, "debtor"))
        ->Js.Array2.concat(entriesFromNestedData(data, defaultAdditionalInfoEntries, "additionalInfo"))
      | _ => defaultEntries //failwith("Expected an object")
      }
    } catch {
    | _ => defaultEntries
    }
    ->Js.Dict.fromArray

} 