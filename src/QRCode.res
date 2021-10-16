
/*

Links:
https://www.paymentstandards.ch/dam/downloads/ig-qr-bill-en.pdf#page=39

*/

type entry = (string, string)



let valueFromEntry: Js.Dict.t<string> => string => string =
  data =>
  key =>
  switch Js.Dict.get(data, key) {
  | Some(x) => x
  | None => ""
  }



let stringFromEntries: array<entry> => string =
  entries =>
  Js.Dict.fromArray(entries)
  ->data =>
    [
      // header
      "SPC",
      "0200",
      "1",

      // account
      data->valueFromEntry("iban"),

      // creditor
      "K",
      data->valueFromEntry("creditorName"),
      data->valueFromEntry("creditorAddressLine1"),
      data->valueFromEntry("creditorAddressLine2"),
      "",
      "",
      data->valueFromEntry("creditorCountryCode"),
      
      // ultimate creditor (future FEATURE)
      "",
      "",
      "",
      "",
      "",
      "",
      "",

      // payment amount information
      data->valueFromEntry("amount"),
      data->valueFromEntry("currency"),

      // ultimate debtor
      "K",
      data->valueFromEntry("debtorName"),
      data->valueFromEntry("debtorAddressLine1"),
      data->valueFromEntry("debtorAddressLine2"),
      "",
      "",
      data->valueFromEntry("debtorCountryCode"),

      // reference
      data->valueFromEntry("referenceType"),
      data->valueFromEntry("reference"),

      // additional information
      data->valueFromEntry("message"),
      "EPD",
      data->valueFromEntry("messageCode"),

      // alternative information (IMPLEMENT)
      "",
      ""
    ]
  ->Js.Array2.joinWith("\n")

