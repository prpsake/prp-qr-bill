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



let defaultAddressData: addressData = {
  addressType: Default({ key: "addressType", val: "" }),
  name: Default({ key: "name", val: "" }),
  street: Default({ key: "street", val: "" }),
  streetNumber: Default({ key: "streetNumber", val: "" }),
  postOfficeBox: Default({ key: "postOfficeBox", val: "" }),
  postalCode: Default({ key: "postalCode", val: "" }),
  locality: Default({ key: "locality", val: "" }),
  countryCode: Default({ key: "countryCode", val: "" })
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
  creditor: Default({ key: "creditor", val: defaultAddressData }),
  debtor: Default({ key: "debtor", val: defaultAddressData }),
}



let dictGet: Js.Dict.t<string> => string => string =
  d =>
  key =>
  switch Js.Dict.get(d, key) {
  | Some(x) => x
  | None => ""
  }



let fold: dataOption<string> => string =
  o =>
  switch o {
  | User({ val }) => val
  | Default({ val }) => val
  | Error({ val }) => "Error: " ++ val
  | None => ""
  }



let addQrCodeStringFromEntries: array<(string, string)> => array<(string, string)> =
  xs =>
  Js.Dict.fromArray(xs)
  ->d =>
    [
      // header
      "SPC",
      "0200",
      "1",

      // account
      d->dictGet("iban"),

      // creditor
      d->dictGet("creditorAddressType"),
      d->dictGet("creditorName"),
      d->dictGet("creditorAddressLine1"),
      d->dictGet("creditorAddressLine2"),
      "",
      "",
      d->dictGet("creditorCountryCode"),

      // ultimate creditor (future FEATURE)
      "",
      "",
      "",
      "",
      "",
      "",
      "",

      // payment amount information
      d->dictGet("amount"),
      d->dictGet("currency"),

      // ultimate debtor
      d->dictGet("debtorAddressType"),
      d->dictGet("debtorName"),
      d->dictGet("debtorAddressLine1"),
      d->dictGet("debtorAddressLine2"),
      "",
      "",
      d->dictGet("debtorCountryCode"),

      // reference
      d->dictGet("referenceType"),
      d->dictGet("reference"),

      // additional information
      d->dictGet("message"),
      "EPD",
      d->dictGet("messageCode"),

      // alternative information (IMPLEMENT)
      "",
      ""
    ]
  ->Js.Array2.joinWith("\n")
  ->x => [("qrCodeString", x)]
  ->Js.Array2.concat(xs)



let addressEntries: dataOption<addressData> => string => array<(string, string)> =
  d =>
  key =>
  switch d {
  | User({ val }) => val
  | _ => defaultAddressData
  }
  ->ad => {
      let addressLine1 = 
        switch ad.postOfficeBox {
        | User({ val }) => val
        | _ => 
          (ad.street->fold ++ " " ++ ad.streetNumber->fold)
          ->Js.String2.trim
        }

      let addressLine2 =
        (ad.postalCode->fold ++ " " ++ad.locality->fold)
        ->Js.String2.trim

      [
        (key ++ "AddressType", "K"),
        (key ++ "Name", ad.name->fold),
        (key ++ "AddressLine1", addressLine1),
        (key ++ "AddressLine2", addressLine2),
        (key ++ "CountryCode", ad.countryCode->fold),
      ]
    }



let entries: data => array<(string, string)> =
  d =>
  [
    ("lang", d.lang->fold),
    ("currency", d.currency->fold),
    ("amount", d.amount->fold),
    ("iban", d.iban->fold),
    ("referenceType", d.referenceType->fold),
    ("reference", d.reference->fold),
    ("message", d.message->fold),
    ("messageCode", d.messageCode->fold)
  ]
  ->xs =>
    d.creditor
    ->addressEntries("creditor")
    ->Js.Array2.concat(xs)
  ->xs =>
    d.debtor
    ->addressEntries("debtor")
    ->Js.Array2.concat(xs)
  ->addQrCodeStringFromEntries