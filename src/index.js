import { define, html, property } from 'hybrids'



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

    <style>

      :host {
        display: flex;
        width: 210mm;
        height: 105mm;
        border: 1pt solid #000;
        font-family: LiberationSans, sans-serif;
        font-weight: 400;
        color: #000;
      }

      :host * {
        box-sizing: border-box;
      }

      .title {
        height: 7mm;
        font-weight: 700;
        font-size: 11pt;
        line-height: 1;
      }

      .receipt {
        display: flex;
        flex-direction: column;
        width: 62mm;
        padding: 5mm;
        border-right: 1pt solid #000;
      }

      .receipt .heading {
        font-weight: 700;
        font-size: 6pt;
        line-height: 9pt;
      }

      .receipt .value {
        font-size: 8pt;
        line-height: 9pt;
        margin-bottom: 9pt;
      }

      .receipt .information {
        height: 56mm;
      }

      .receipt .amount {
        height: 14mm;
      }

      .receipt .acceptance-point {
        height: 18mm;
      }

      .payment-part {
        width: 148mm;
      }

    </style>

    <div class="receipt">
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

    <div class="payment-part"></div>

  `
}



define(AQRBill)