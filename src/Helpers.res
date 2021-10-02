// type data = {
//   lang: "de",
//   currency: "CHF",
//   amount: "143250",
//   iban: "CH1234567890123456789",
//   reference: "RF18539007547034",
//   creditor: {
//     name: "Kat Kitty",
//     street: "Einerstrasse",
//     streetNumber: "1E",
//     postOfficeBox: "Postfach 8888",
//     postalCode: "1111",
//     locality: "Einerstadt",
//     countryCode: "CH"
//   },
//   debtor: {
//     name: "Dog Dodgy",
//     street: "Zweierstrasse 2",
//     locality: "2222 Zweierstadt",
//     countryCode: "CH"
//   },
//   additionalInfo: {
//     message: "Rechnung #02021",
//     code: ""
//   }
// }


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



let valueFromKey: Js.Dict.t<'a> => Js.Dict.t<'a> => string => Js.Json.t =
  defaultData =>
  data =>
  key =>
  switch Js.Dict.get(data, key) {
  | Some(x) =>
    switch Js.Json.classify(x) {
    | Js.Json.JSONString(x) => Js.Json.string(x)
    | _ =>
      switch Js.Dict.get(defaultData, key) {
      | Some(x) =>
        switch Js.Json.classify(x) {
        | Js.Json.JSONString(x) => Js.Json.string(x)
        | _ => Js.Json.string("")
        }
      | None => Js.Json.string("")
      }
    }
  | None =>
    switch Js.Dict.get(defaultData, key) {
    | Some(x) =>
      switch Js.Json.classify(x) {
      | Js.Json.JSONString(x) => Js.Json.string(x)
      | _ => Js.Json.string("")
      }
    | None => Js.Json.string("")
    }
  }


let parseJson =
  s => {
    let json = 
      try Js.Json.parseExn(s)
      catch {
      | _ => Js.Json.object_(defaultData)
      }
    switch Js.Json.classify(json) {
    | Js.Json.JSONObject(data) =>
      let valueFromRootKey = valueFromKey(defaultData, data)
      let valueFromAddressKey = valueFromKey(defaultAddressData)
      Js.Dict.fromArray([
        ("lang",      valueFromRootKey("lang")),
        ("currency",  valueFromRootKey("currency")),
        ("amount",    valueFromRootKey("amount")),
        ("iban",      valueFromRootKey("iban")),
        ("reference", valueFromRootKey("reference")),
        ("creditor",
          switch Js.Dict.get(data, "creditor") {
          | Some(json) =>
            switch Js.Json.classify(json) {
            | Js.Json.JSONObject(addressData) =>
              Js.Json.object_(Js.Dict.fromArray([
                ("name", valueFromAddressKey(addressData, "name"))
              ]))
            | _ => Js.Json.object_(defaultAddressData)
            }
          | None => Js.Json.object_(defaultAddressData)
          }
        )
      ])
    | _ => failwith("Expected an object")
    }
  }






let reverseStr: string => string =
  x =>
  Js.String2.split(x, "")
  ->Js.Array2.reverseInPlace
  ->Js.Array2.joinWith("")



let blockStr: string => string => string =
  n =>
  x =>
  switch Js.Types.classify(x) {
  | JSString(x) => 
    let x_ = Js.String2.replaceByRe(x, %re("/\s/g"), "")
    let pat = Js.Re.fromStringWithFlags("\\S{"++ n ++"}", ~flags="g")
    Js.String2.replaceByRe(x_, pat, "$& ")
  | _ => ""
  }



let blockStr3 = blockStr("3")
let blockStr4 = blockStr("4")
let blockStr5 = blockStr("5")



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



let moneyFromScaledIntStr: int => string => string =
  n =>
  x =>
  switch Js.Types.classify(x) {
  | JSString(x) =>
    let xTrim = Js.String2.trim(x)
    xTrim
    ->Js.String2.slice(~from=0, ~to_=-n)
    ->reverseStr
    ->blockStr3
    ->reverseStr
    ++ "." 
    ++ Js.String2.sliceToEnd(xTrim, ~from=-n)
  | _ => ""
  }



let moneyFromScaledIntStr2 = moneyFromScaledIntStr(2)








