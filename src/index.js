/*

  Links:
  https://www.paymentstandards.ch/dam/downloads/style-guide-en.pdf
  https://www.paymentstandards.ch/de/shared/communication-grid.html
  https://www.paymentstandards.ch/dam/downloads/ig-qr-bill-de.pdf
  - Datatypes: https://www.paymentstandards.ch/dam/downloads/ig-qr-bill-de.pdf#page=27
*/

import styles from './index.ass.css'
import { define, html } from 'hybrids'
import { showWith, notShowWith, fn } from './Helpers.js'
import { translate } from './Translations.bs.js'
import * as Parser from './Parser.bs.js'
import * as Validator from './Validator.bs.js'
import * as Data from './Data.bs.js'
import * as Formatter from './Formatter.bs.js'
import * as QRCode from './QRCode.bs.js'



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
    overflow="visible"
    class="block text-black stroke-current"
    style=${{
      width: `${width}mm`,
      height: `${height}mm`,
      ...styles
    }}>
    <path 
      shape-rendering="crispEdges" 
      vector-effect="non-scaling-stroke" 
      stroke-width="1" 
      d="M 3,0 h -3 v 3"/>
    <path 
      shape-rendering="crispEdges" 
      vector-effect="non-scaling-stroke" 
      stroke-width="1" 
      d="M ${width - 3},0 h 3 v 3"/>
    <path 
      shape-rendering="crispEdges" 
      vector-effect="non-scaling-stroke" 
      stroke-width="1" 
      d="M 3,${height} h -3 v -3"/>
    <path 
      shape-rendering="crispEdges" 
      vector-effect="non-scaling-stroke" 
      stroke-width="1" 
      d="M ${width - 3},${height} h 3 v -3"/>
  </svg>`



const svgQRCode = 
  str => 
  html`
  <svg 
    width="100%"
    height="100%"
    viewBox="0 0 570 570"
    class="block text-black fill-current">
    <path 
      x="0" y="0"
      shape-rendering="crispEdges"
      d="${QRCode.pathDataFromString(str, {
        ecl: "M",
        width: 570,
        height: 570,
        padding: 0
      })}"/>
    <rect 
      x="245" y="245" 
      width="80" 
      height="80"/>
    <path
      fill="#fff"
      fill-rule="evenodd"
      shape-rendering="crispEdges"
      d="M328.37,241.63L241.63,241.63L241.63,328.37L328.37,328.37L328.37,241.63ZM325.069,244.931L244.931,244.931L244.931,325.069L325.069,325.069L325.069,244.931ZM293.014,275.572L293.014,257.187L277.458,257.187L277.458,275.572L259.073,275.572L259.073,291.128L277.458,291.128L277.458,309.041L293.014,309.041L293.014,291.128L310.927,291.128L310.927,275.572L293.014,275.572Z"/>
  </svg>`



export default define({
  tag: 'a-qr-bill',
  data: {
    set(_, json) {
      return (
      [json]
      .map(Parser.parseJson)
      .map(Validator.validate)
      .map(Data.entries)
      [0]
    )},
    observe(host, entries) {
      entries.forEach(([k, v]) => host[k] = v)
      host.showQRCode = false //notShowWith(host, { qrCodeString: [''] })
      host.showAmount = notShowWith(host, { amount: [''] })
      host.showReference = showWith(host, { referenceType: ['QRR', 'SCOR'] })
      host.showDebtor = notShowWith(host, { debtorName: [''], debtorAddressLine1: [''], debtorAddressLine2: [''] })
      host.showAdditionalInfo = notShowWith(host, { message: [''], messageCode: [''] })
    }
  },

  lang: fn(translate),

  currency: '',
  amount: fn(Formatter.moneyFromNumberStr2),
  iban: fn(Formatter.blockStr4),
  referenceType: '',
  reference: fn(Formatter.referenceBlockStr),
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

  qrCodeString: '',

  showQRCode: false,
  showAmount: false,
  showReference: false,
  showDebtor: false,
  showAdditionalInfo: false,

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
    
    qrCodeString,

    showQRCode,
    showAmount,
    showReference,
    showAdditionalInfo,
    showDebtor,

    reduceContent

  }) => html`

  <div class="w-62 p-5 border-t border-r border-dashed border-black scissors-br">

    <div class="h-7 font-bold text-11 leading-none">${lang.receiptTitle}</div>

    <div class="h-56">
      <div class="font-bold text-6 leading-9">${lang.creditorHeading}</div>
      <div class="text-8 leading-9 mb-line-9">
        <div>${iban}</div>
        <div>${creditorName}</div>
        ${!reduceContent && html`<div>${creditorAddressLine1}</div>`}
        <div>${creditorAddressLine2}</div>
      </div>

      ${showReference && html`
        <div class="font-bold text-6 leading-9">${lang.referenceHeading}</div>
        <div class="text-8 leading-9 mb-line-9">
          <div>${reference}</div>
        </div>
      `}

      <div class="font-bold text-6 leading-9">
        ${showDebtor ? lang.debtorHeading : lang.debtorFieldHeading}
      </div>
      ${showDebtor ? html`
        <div class="text-8 leading-9">
          <div>${debtorName}</div>
          ${!reduceContent && html`<div>${debtorAddressLine1}</div>`}
          <div>${debtorAddressLine2}</div>
        </div>
      ` : svgBlankField(52, 20, { marginTop: '.8pt' })}
    </div>

    <div class="h-14 flex">
      <div class="flex-shrink w-22">
        <div class="font-bold text-6 leading-9">${lang.currencyHeading}</div>
        <div class="text-8 leading-9">${currency}</div>
      </div>

      <div class=${{ 'flex-grow': true, flex: !showAmount }}>
        <div class="font-bold text-6 leading-9">${lang.amountHeading}</div>
        ${showAmount ? 
          html`<div class="text-8 leading-9">${amount}</div>` : 
          svgBlankField(30, 10, { marginTop: '2pt', marginLeft: '4pt' })
        }
      </div>
    </div>

    <div class="h-18 font-bold text-6 text-right">${lang.acceptancePointHeading}</div>
  </div>

  <div class="w-148 p-5 border-t border-dashed border-black scissors-tr">
    <div class="h-85 flex">
      <div class="w-51">
        <div class="h-7 font-bold text-11 leading-none">${lang.paymentPartTitle}</div>

        <div class="h-56 py-5 pr-5">
          ${showQRCode ? 
            svgQRCode(qrCodeString, showQRCode) : 
            svgBlankField(46, 46)
          }
        </div>

        ${showAmount ? html`
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
        ` : html`
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
        `}
      </div>

      <div class="w-87">
        <div class="font-bold text-8 leading-11">${lang.creditorHeading}</div>
        <div class="text-10 leading-11 mb-line-11">
          <div>${iban}</div>
          <div>${creditorName}</div>
          <div>${creditorAddressLine1}</div>
          <div>${creditorAddressLine2}</div>
        </div>

        ${showReference && html`
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
          ${showDebtor ? lang.debtorHeading : lang.debtorFieldHeading}
        </div>
        ${showDebtor ? html`
          <div class="text-10 leading-11">
            <div>${debtorName}</div>
            <div>${debtorAddressLine1}</div>
            <div>${debtorAddressLine2}</div>
          </div>
        ` : svgBlankField(65, 25, { marginTop: '1.1pt' })}
      </div>

    </div>
    <div class="h-10"></div>
  </div>

  `.style(styles)
})