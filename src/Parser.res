type entry = (string, Js.Json.t)



let defaultRootEntries: array<entry> = {
  open Js.Json
  [
    ("lang", string("en")),
    ("currency", string("")),
    ("amount", string("")),
    ("iban", string("")),
    ("reference", string("")),
    ("message", string("")),
    ("messageCode", string(""))
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



let defaultEntries: array<entry> = {
  open Js.Json
  defaultRootEntries
  ->Js.Array2.concat([
    ("creditor", object_(Js.Dict.fromArray(defaultAddressEntries))),
    ("debtor", object_(Js.Dict.fromArray(defaultAddressEntries)))
  ])
}



let prefixEntryKeysWith: array<entry> => string => array<entry> =
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
    | JSONString(x) => (k, Js.Json.string(x))
    | JSONNumber(x) => (k, Js.Json.string(Belt.Float.toString(x)))
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
    | JSONObject(nestedData) =>
      defaultNestedEntries
      ->Js.Array2.map(entryFromData(nestedData))
    | _ => defaultNestedEntries
    }
  | None => defaultNestedEntries
  }



let referenceTypeEntryFromEntries: array<entry> => array<entry> =
  entries =>
  Js.Dict.fromArray(entries)
  ->data =>
    switch Js.Dict.get(data, "reference") {
    | Some(x) =>
      switch Js.Json.classify(x) {
      | JSONString(x) => x != ""
      | _ => false
      }
    | None => false
    }
  ->existsReferenceEntry =>
    switch Js.Dict.get(data, "iban") {
    | Some(x) =>
      switch Js.Json.classify(x) {
      | JSONString(x) =>
        Formatter.removeWhitespace(x)
        ->Js.String2.substring(~from=4, ~to_=5)
        ->value =>
          value == "3" ? "QRR"
          : 
          (existsReferenceEntry ? "SCOR" : "NON")
      | _ => "NON"
      }
    | None => "NON"
  }
  ->value => [("referenceType", Js.Json.string(value))]
  ->Js.Array2.concat(entries)



let addressTypeEntryFromEntries: array<entry> => array<entry> =
  entries =>
  Js.Array2.filter(
    entries, 
    ((k, _)) => k == "streeNumber" || k == "postalCode"
  )
  ->Js.Array2.some(
      ((_, v)) =>
      switch Js.Json.classify(v) {
      | JSONString(v) => v != ""
      | _ => false
      } 
    )
  ->isStructured => (isStructured ? "S" : "K")
  ->value => [("addressType", Js.Json.string(value))]
  ->Js.Array2.concat(entries)



let rootEntriesFromData: Js.Dict.t<Js.Json.t> => array<entry> =
  data => 
  defaultRootEntries
  ->Js.Array2.map(entryFromData(data))
  ->referenceTypeEntryFromEntries



let addressEntriesFromData: Js.Dict.t<Js.Json.t> => string => array<entry> =
  data =>
  key =>
  entriesFromNestedData(data, defaultAddressEntries, key)
  ->addressTypeEntryFromEntries
  ->prefixEntryKeysWith(key)



let parseJson: string => array<entry> =
  str =>
  try {
    let json = Js.Json.parseExn(str)
    switch Js.Json.classify(json) {
    | JSONObject(data) =>
      rootEntriesFromData(data)
      ->Js.Array2.concat(addressEntriesFromData(data, "creditor"))
      ->Js.Array2.concat(addressEntriesFromData(data, "debtor") )
    | _ => defaultEntries //failwith("Expected an object")
    }
  } catch {
  | _ => defaultEntries
  }
  //->Js.Dict.fromArray