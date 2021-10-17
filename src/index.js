/*
  NB:
  Some possible versions:
  1: QR-IBAN (CHXX 3XXX ...)
     + 
     QR reference (XX XXXXX XXXXX ...)

  2: IBAN (CHXX XXXX ...)
     +
     Creditor reference (RFXX XXXX ...)

  3: IBAN
     w/o reference


  Links:
  https://www.paymentstandards.ch/dam/downloads/style-guide-en.pdf
  https://www.paymentstandards.ch/de/shared/communication-grid.html
  https://www.paymentstandards.ch/dam/downloads/ig-qr-bill-de.pdf
  - Datatypes: page 27
*/


import styles from './index.a.css'
import { define, html, property } from 'hybrids'
import { setBoolFromVersions } from './Factories.js'
import { translate } from './Translations.bs.js'
import * as Parser from './Parser.bs.js'
import * as Validator from './Validator.bs.js'
import * as Formatter from './Formatter.bs.js'
import * as QRCode from './QRCode.bs.js'
import { QRCode as QRCodeSVG } from './qrcode-svg.js'



/* NB: 
   stroke-width 0.4 (mm) is a visual approximation.
   Style-guide states 0.75pt which is 0.2635 or so, but looks
   too thin compared to the example in the guide.
*/
const svgBlankField = 
  (width, height, styles = {}) => 
  html`
  <svg 
    viewBox="0 0 ${width} ${height}"
    fill="none"
    class="block text-black stroke-current"
    style=${{
      width: `${width}mm`,
      height: `${height}mm`,
      ...styles
    }}>
    <path d="M 3,0 h -3 v 3" stroke-width="0.5"/>
    <path d="M ${width - 3},0 h 3 v 3" stroke-width="0.5"/>
    <path d="M 3,${height} h -3 v -3" stroke-width="0.5"/>
    <path d="M ${width - 3},${height} h 3 v -3" stroke-width="0.5"/>
  </svg>`



const svgQRCode = 
  content => 
  html`
  <svg 
    width="100%"
    height="100%"
    viewBox="0 0 570 570"
    class="block text-black fill-current">
    <path 
      x="0" y="0"
      shape-rendering="crispEdges"
      d="${new QRCodeSVG({
        content,
        ecl: "M",
        width: 570,
        height: 570,
        padding: 0
      }).svgPathData()}"/> 
    <rect 
      x="245" y="245" 
      width="80" 
      height="80"/>
    <path
      fill="#fff"
      fill-rule="evenodd" 
      d="M328.37,241.63L241.63,241.63L241.63,328.37L328.37,328.37L328.37,241.63ZM325.069,244.931L244.931,244.931L244.931,325.069L325.069,325.069L325.069,244.931ZM293.014,275.572L293.014,257.187L277.458,257.187L277.458,275.572L259.073,275.572L259.073,291.128L277.458,291.128L277.458,309.041L293.014,309.041L293.014,291.128L310.927,291.128L310.927,275.572L293.014,275.572Z"/>
  </svg>`



const AQRBill = {
  tag: 'a-qr-bill',
  data: property(Parser.parseJson, (host, key) => {
    const entries = Validator.validateEntries(host[key])
    host.qrCodeContent = QRCode.stringFromEntries(entries)
    entries.forEach(([k, v]) => host[k] = v)
  }),

  version: '',
  lang: property(translate),

  currency: '',
  amount: property(Formatter.moneyFromNumberStr2),
  iban: property(Formatter.blockStr4),
  referenceType: '',
  reference: property(Formatter.referenceBlockStr),
  message: '', // Notification (unstructred)
  messageCode: '', // Bill Information (structured)

  creditorName: '',
  creditorAddressLine1: '',
  creditorAddressLine2: '',
  creditorCountryCode: '',

  debtorName: '',
  debtorAddressLine1: '',
  debtorAddressLine2: '',
  debtorCountryCode: '',

  qrCodeContent: '',

  showReference: setBoolFromVersions(['1a', '1b', '2a', '2b']),
  showAdditionalInfo: setBoolFromVersions(['1a', '1b', '2a', '2b']),
  showBlanks: setBoolFromVersions(['3b']),

  reduceContent: false,

  render: ({
    lang,

    currency,
    amount,
    iban,
    reference,
    message,
    messageCode,

    creditorName,
    creditorAddressLine1,
    creditorAddressLine2,

    debtorName,
    debtorAddressLine1,
    debtorAddressLine2,

    showReference,
    showAdditionalInfo,
    showBlanks,

    qrCodeContent,

    reduceContent

  }) => html`

  <div class="flex flex-col w-62 p-5">

    <div class="h-7 font-bold text-11 leading-none">${lang.receiptTitle}</div>

    <div class="h-56">
      <div class="font-bold text-6 leading-9">${lang.creditorHeading}</div>
      <div class="text-8 leading-9 mb-line-9">
        <div>${iban}</div>
        <div>${creditorName}</div>
        ${!reduceContent && html`<div>${creditorAddressLine1}</div>`}
        <div>${creditorAddressLine2}</div>
      </div>

      ${showReference && reference && html`
        <div class="font-bold text-6 leading-9">${lang.referenceHeading}</div>
        <div class="text-8 leading-9 mb-line-9">
          <div>${reference}</div>
        </div>
      `}

      <div class="font-bold text-6 leading-9">
        ${showBlanks ? lang.debtorFieldHeading : lang.debtorHeading}
      </div>
      ${showBlanks ? svgBlankField(52, 20, { marginTop: '.8pt' }) : html`
        <div class="text-8 leading-9">
          <div>${debtorName}</div>
          ${!reduceContent && html`<div>${debtorAddressLine1}</div>`}
          <div>${debtorAddressLine2}</div>
        </div>
      `}
    </div>

    <div class="h-14 flex">
      <div class="flex-shrink w-22">
        <div class="font-bold text-6 leading-9">${lang.currencyHeading}</div>
        <div class="text-8 leading-9">${currency}</div>
      </div>

      <div class=${{ 'flex-grow': true, flex: showBlanks }}>
        <div class="font-bold text-6 leading-9">${lang.amountHeading}</div>
        ${showBlanks ? svgBlankField(30, 10, { marginTop: '2pt', marginLeft: '4pt' }) : html`
          <div class="text-8 leading-9">${amount}</div>
        `}
      </div>
    </div>

    <div class="h-18 font-bold text-6 text-right">${lang.acceptancePointHeading}</div>
  </div>

  <div class="flex flex-col w-148 p-5">
    <div class="h-85 flex">
      <div class="w-51">
        <div class="h-7 font-bold text-11 leading-none">${lang.paymentPartTitle}</div>

        <div class="h-56 py-5 pr-5">
          ${svgQRCode(qrCodeContent)}
        </div>

        ${showBlanks ? html`
          <div class="h-22">
            <div class="flex font-bold text-8 leading-11">
              <div class="mr-line-7">${lang.currencyHeading}</div>
              <div>${lang.amountHeading}</div>
            </div>
            <div class="flex">
              <div class="text-10 leading-11 mr-line-9">${currency}</div>
              ${svgBlankField(40, 15, { marginTop: '1.6pt' })}
            </div>
          </div>
        ` : html`
          <div class="h-22 flex">
            <div class="flex-shrink w-22">
              <div class="font-bold text-8 leading-11">${lang.currencyHeading}</div>
              <div class="text-10 leading-11">${currency}</div>
            </div>

            <div class="flex-grow">
              <div class="font-bold text-8 leading-11">${lang.amountHeading}</div>
              <div class="text-10 leading-11">${amount}</div>
            </div>
          </div>
        `}
      </div>

      <div class="w-87">
        <div class="font-bold text-8 leading-11">${lang.creditorHeading}</div>
        <div class="text-10 leading-11 mb-line-11">
          <div>${iban}</div>
          <div>${creditorName}</div>
          ${!reduceContent && html`<div>${creditorAddressLine1}</div>`}
          <div>${creditorAddressLine2}</div>
        </div>

        ${showReference && reference && html`
          <div class="font-bold text-8 leading-11">${lang.referenceHeading}</div>
          <div class="text-10 leading-11 mb-line-11">
            <div>${reference}</div>
          </div>
        `}

        ${showAdditionalInfo && html`
          <div class="font-bold text-8 leading-11">${lang.additionalInfoHeading}</div>
          <div class="text-10 leading-11 mb-line-11">
            ${message && html`<div>${message}</div>`}
            ${messageCode && html`<div>${messageCode}</div>`}
          </div>     
        `}

        <div class="font-bold text-8 leading-11">
          ${showBlanks ? lang.debtorFieldHeading : lang.debtorHeading}
        </div>
        ${showBlanks ? svgBlankField(65, 25, { marginTop: '1.1pt' }) : html`
          <div class="text-10 leading-11">
            <div>${debtorName}</div>
            ${!reduceContent && html`<div>${debtorAddressLine1}</div>`}
            <div>${debtorAddressLine2}</div>
          </div>
        `}
      </div>

    </div>
    <div class="h-10"></div>
  </div>

  `.style(styles)
}



define(AQRBill)