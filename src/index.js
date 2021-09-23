import { define, html, property } from 'hybrids'
import styles from './index.a.css'



const translations = {
  en: {
    'Payment part': 'Payment part',
    'Account / Payable to': 'Account / Payable to',
    'Reference': 'Reference',
    'Additional information': 'Additional information',
    'Further information': 'Further information',
    'Currency': 'Currency',
    'Amount': 'Amount',
    'Receipt': 'Receipt',
    'Acceptance point': 'Acceptance point',
    'Separate before paying in': 'Separate before paying in',
    'Payable by': 'Payable by',
    'Payable by (name/address)': 'Payable by (name/address)',
    'In favour of': 'In favour of'
  }
}




const blockString =
  len =>
  str => {
    if (str === undefined) return ''
    return (
      str
      .replace(/\s/g, '')
      .replace(RegExp(`\\S{${len}}`, 'g'), '$& ')
      .trim()
    )
  }



const AQRBill = {
  tag: 'a-qr-bill',

  /* Titles / Headings */
  receiptTitle: 'Receipt',
  receiptInformationHeading: 'Account / Payable to',
  receiptReferenceHeading: 'Reference',

  /* Values */
  iban: property(blockString(4)),

  render: ({

    receiptTitle,
    receiptInformationHeading,
    receiptReferenceHeading,

    iban

  }) => html`

    <div class="flex flex-col w-62 p-5 border-r">

      <div class="h-7 font-bold text-11 leading-none">${receiptTitle}</div>

      <div class="h-56">
        <div class="font-bold text-6 leading-9">${receiptInformationHeading}</div>
        <div class="text-8 leading-9 mb-line-9">
          <div>${iban}</div>
        </div>

        <div class="font-bold text-6 leading-9">${receiptReferenceHeading}</div>
        <div class="text-8 leading-9 mb-line-9">
          <div>${iban}</div>
        </div>
      </div>

      <div class="h-14"></div>
      <div class="h-18"></div>
    </div>

    <div class="w-148"></div>

  `.style(styles)
}



define(AQRBill)