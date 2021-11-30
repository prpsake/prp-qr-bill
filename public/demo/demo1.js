import { define } from 'hybrids';
import AQRBill from '../index.js'



document
.getElementById('qr-bill')
.data = {
  lang: "de",
  currency: "CHF",
  amount: 87.75,
  iban: "CH1509000000152034087",
  reference: "RF18539007547034",
  message: "Rechnung #02521",
  messageCode: "//acc:blub//blah:n98189//cool:code//wow",
  creditor: {
    name: "Jérôme Imfeld",
    street: "Grätzlistrasse",
    streetNumber: "3",
    postOfficeBox: "Postfach 8888",
    postalCode: 8152,
    locality: "Opfikon",
    countryCode: "CH"
  },
  debtor: {
    name: "Jungle Folk GmbH",
    street: "Sihlquai 55",
    locality: "8005 Zürich",
    countryCode: "CH"
  }
}



define(AQRBill)

