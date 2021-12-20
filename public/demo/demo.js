import { store, define, html } from "hybrids";
import { showWith, notShowWith } from "./Helpers.js"
import * as Parser from "../Parser.bs.js"
import * as Validator from "../Validator.bs.js"
import * as Data from "../Data.bs.js"
import * as Formatter from "../Formatter.bs.js"



import AQRBill from "../index.js"



const QRBillData = {
  lang: "",
  currency: "",
  amount: "",
  iban: "",
  reference: "",
  message: "",
  messageCode: "",
  creditorName: "",
  creditorAddressLine1: "",
  creditorAddressLine2: "",
  debtorName: "",
  debtorAddressLine1: "",
  debtorAddressLine2: "",
  qrCodeString: "",
  [store.connect]: {
    get: () => 
      fetch("demo.json")
      .then(data => data.json())
      .then(json =>
        [json]
        .map(Parser.parseJson)
        .map(Validator.validate)
        .map(Data.object)
        [0]
      ),
    set: (_, values) => values
  }
}



define({
  tag: "the-app",
  data: store(QRBillData),
  render: ({ data }) => html`
    ${store.ready(data) && html`
      <a-qr-bill
        lang=${data.lang}
        currency=${data.currency}
        amount=${Formatter.moneyFromNumberStr2(data.amount)}
        iban=${Formatter.blockStr4(data.iban)}
        reference=${Formatter.referenceBlockStr(data.reference)}
        message=${data.message}
        messageCode=${data.messageCode}
        creditorName=${data.creditorName}
        creditorAddressLine1=${data.creditorAddressLine1}
        creditorAddressLine2=${data.creditorAddressLine2}
        debtorName=${data.debtorName}
        debtorAddressLine1=${data.debtorAddressLine1}
        debtorAddressLine2=${data.debtorAddressLine2}
        qrCodeString=${data.qrCodeString}
        showQRCode=${notShowWith(data, { qrCodeString: [""] })}
        showAmount=${notShowWith(data, { amount: [""] })}
        showReference=${showWith(data, { referenceType: ["QRR", "SCOR"] })}
        showDebtor=${notShowWith(data, { debtorName: [""], debtorAddressLine1: [""], debtorAddressLine2: [""] })}
        showAdditionalInfo=${notShowWith(data, { message: [""], messageCode: [""] })}
        reduceContent=${false}>
      </a-qr-bill>
    `}
  `
}, AQRBill)
