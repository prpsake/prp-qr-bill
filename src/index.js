import { define, html, property } from 'hybrids'
import styles from './index.a.css'



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

  /* Values */
  iban: property(blockString(4)),

  render: ({

    receiptTitle,
    receiptInformationHeading,

    iban

  }) => html`

    <div class="w-62 p-5 border-r border-solid border-black">
      <div class="title">${receiptTitle}</div>
      <div class="information">
        <div class="heading">${receiptInformationHeading}</div>
        <div class="value">
          <div>${iban}</div>
        </div>
      </div>
      <div class="amount"></div>
      <div class="acceptance-point"></div>
    </div>

    <div class="payment-part w-148"></div>

  `.style(styles)
}



define(AQRBill)