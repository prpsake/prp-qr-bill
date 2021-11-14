import { store, define, html } from 'hybrids';
import AQRBill from '../index.js'



const QRBillAddressData = {
  name: '',
  street: '',
  streetNumber: '',
  postOfficeBox: '',
  postalCode: '',
  locality: '',
  countryCode: ''
}



const QRBillData = {
  lang: '',
  currency: '',
  amount: '',
  iban: '',
  reference: '',
  message: '',
  messageCode: '',
  creditor: QRBillAddressData,
  debtor: QRBillAddressData, 
  [store.connect] : () => fetch('demo2.json').then(data => data.json())
}



define({
  tag: 'the-app',
  qrBillData: store(QRBillData),
  render: ({ qrBillData }) => html`
    ${store.ready(qrBillData) && html`
      <a-qr-bill data=${qrBillData} showQRCode></a-qr-bill>
    `}
  `
}, AQRBill)
