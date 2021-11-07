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



let fold: dataOption<'a> => 'a =
  o =>
  switch o {
  | User({ val }) => val
  | Default({ val }) => val
  | Error({ val }) => "Error: " ++ val
  | None => ""
  }


let entries: data => array<array<string>> =
  d =>
  [
    ["lang", d.lang->fold],
    ["currency", d.currency->fold],
    ["amount", d.amount->fold],
    ["iban", d.iban->fold],
    ["referenceType", d.referenceType->fold],
    ["reference", d.reference->fold],
    ["message", d.message->fold],
    ["messageCode", d.messageCode->fold]
  ]
