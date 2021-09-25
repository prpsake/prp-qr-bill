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
*/


import { define, html, property } from 'hybrids'
import styles from './index.a.css'



const translations = {
  en: {
    paymentPartTitle: 'Payment part',
    creditorHeading: 'Account / Payable to',
    referenceHeading: 'Reference',
    additionalInfoHeading: 'Additional information',
    furtherInfoHeading: 'Further information',
    currencyHeading: 'Currency',
    amountHeading: 'Amount',
    receiptTitle: 'Receipt',
    acceptancePointHeading: 'Acceptance point',
    separateText: 'Separate before paying in',
    debtorHeading: 'Payable by',
    debtorFieldHeading: 'Payable by (name/address)',
    ultimateCreditorHeading: 'In favour of'
  },
  de: {
    paymentPartTitle: 'Zahlteil',
    creditorHeading: 'Konto / Zahlbar an',
    referenceHeading: 'Referenz',
    additionalInfoHeading: 'Zusätzliche Informationen',
    furtherInfoHeading: 'Weitere Informationen',
    currencyHeading: 'Währung',
    amountHeading: 'Betrag',
    receiptTitle: 'Empfangsschein',
    acceptancePointHeading: 'Annahmestelle',
    separateText: 'Vor der Einzahlung abzutrennen',
    debtorHeading: 'Zahlbar durch',
    debtorFieldHeading: 'Zahlbar durch (Name/Adresse)',
    ultimateCreditorHeading: 'Zugunsten'
  },
  fr: {
    paymentPartTitle: 'Section paiement',
    creditorHeading: 'Compte / Payable à',
    referenceHeading: 'Référence',
    additionalInfoHeading: 'Informations supplémentaires',
    furtherInfoHeading: 'Informations additionnelles',
    currencyHeading: 'Monnaie',
    amountHeading: 'Montant',
    receiptTitle: 'Récépissé',
    acceptancePointHeading: 'Point de dépôt',
    separateText: 'A détacher avant le versement',
    debtorHeading: 'Payable par',
    debtorFieldHeading: 'Payable par (nom/adresse)',
    ultimateCreditorHeading: 'En faveur de'
  },
  it: {
    paymentPartTitle: 'Sezione pagamento',
    creditorHeading: 'Conto / Pagabile a',
    referenceHeading: 'Riferimento',
    additionalInfoHeading: 'Informazioni supplementari',
    furtherInfoHeading: 'Informazioni aggiuntive',
    currencyHeading: 'Valuta',
    amountHeading: 'Importo',
    receiptTitle: 'Ricevuta',
    acceptancePointHeading: 'Punto di accettazione',
    separateText: 'Da staccare prima del versamento',
    debtorHeading: 'Pagabile da',
    debtorFieldHeading: 'Pagabile da (nome/indirizzo)',
    ultimateCreditorHeading: 'A favore di'
  }
}



const translate = 
  lang => 
  translations[lang] || translations.en



const blockStr =
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


const blockStr3 = blockStr(3)
const blockStr4 = blockStr(4)
const blockStr5 = blockStr(5)



const referenceBlockStr =
  str => {
    if (str === undefined) return ''
    const strTrim = str.trim()
    if (strTrim.startsWith('RF')) {
      return blockStr4(strTrim)
    }
    return (
      strTrim.substring(0, 2) + ' ' +
      blockStr5(strTrim.substring(2))
    )
  }



const moneyFromScaledIntStr =
  scale =>
  str => {
    if (str === undefined) return ''
    const strTrim = str.trim()
    return (
      blockStr3(
        strTrim
        .slice(0, -(scale))
        .split('')
        .reverse()
        .join('')
      )
      .split('')
      .reverse()
      .join('') + '.' +
      strTrim.slice(-(scale))
    )
  }



const moneyFromScaledIntStr2 = moneyFromScaledIntStr(2)



const setBoolFromVersions =
  versions =>
  ({
    connect: (host, key) => {
       host[key] = versions.some(x => x === host.version)
    }
  })



/* NB: 
   stroke-width 0.4 (mm) is a visual approximation.
   Style-guide states 0.75pt which is 0.2635 or so, but looks
   too thin compared to the example in the guide.
*/
const blankFieldSVG = 
  (width, height, styles = {}) => html`
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
    </svg>
  `



const AQRBill = {
  tag: 'a-qr-bill',

  version: '',
  lang: property(translate), // en | de | fr | it, defaults en

  iban: property(blockStr4), // QRIBAN | IBAN
  creditorFullName: '',
  creditorStreetPlot: '',
  creditorPostcodeLocality: '',

  reference: property(referenceBlockStr), // QRR | SCOR | None, None omits

  debtorFullName: '',
  debtorStreetPlot: '',
  debtorPostcodeLocality: '',

  currency: '', // CHF | EUR
  amount: property(moneyFromScaledIntStr2), // integer string

  additionalInfo: '', // string (NB: Notification / Bill information)

  showReference: setBoolFromVersions(['1a', '1b', '2a', '2b']),
  showAdditionalInfo: setBoolFromVersions(['1a', '1b', '2a', '2b']),
  showBlanks: setBoolFromVersions(['3b']),

  reduceContent: false,

  render: ({

    lang,

    iban,
    creditorFullName,
    creditorStreetPlot,
    creditorPostcodeLocality,

    reference,

    debtorFullName,
    debtorStreetPlot,
    debtorPostcodeLocality,

    currency,
    amount,

    additionalInfo,

    showReference,
    showAdditionalInfo,
    showBlanks,

    reduceContent

  }) => html`

    <div class="flex flex-col w-62 p-5">

      <div class="h-7 font-bold text-11 leading-none">${lang.receiptTitle}</div>

      <div class="h-56">
        <div class="font-bold text-6 leading-9">${lang.creditorHeading}</div>
        <div class="text-8 leading-9 mb-line-9">
          <div>${iban}</div>
          <div>${creditorFullName}</div>
          ${!reduceContent && html`<div>${creditorStreetPlot}</div>`}
          <div>${creditorPostcodeLocality}</div>
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
        ${showBlanks ? blankFieldSVG(52, 20, { marginTop: '.8pt' }) : html`
          <div class="text-8 leading-9">
            <div>${debtorFullName}</div>
            ${!reduceContent && html`<div>${debtorStreetPlot}</div>`}
            <div>${debtorPostcodeLocality}</div>
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
          ${showBlanks ? blankFieldSVG(30, 10, { marginTop: '2pt', marginLeft: '4pt' }) : html`
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

          <div class="h-56 py-5 pr-5"></div>

          ${showBlanks ? html`
            <div class="h-22">
              <div class="flex font-bold text-8 leading-11">
                <div class="mr-line-7">${lang.currencyHeading}</div>
                <div>${lang.amountHeading}</div>
              </div>
              <div class="flex">
                <div class="text-10 leading-11 mr-line-9">${currency}</div>
               ${blankFieldSVG(40, 15, { marginTop: '1.6pt' })}
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
            <div>${creditorFullName}</div>
            ${!reduceContent && html`<div>${creditorStreetPlot}</div>`}
            <div>${creditorPostcodeLocality}</div>
          </div>

          ${showReference && reference && html`
            <div class="font-bold text-8 leading-11">${lang.referenceHeading}</div>
            <div class="text-10 leading-11 mb-line-11">
              <div>${reference}</div>
            </div>     
          `}

          ${showAdditionalInfo && additionalInfo && html`
            <div class="font-bold text-8 leading-11">${lang.additionalInfoHeading}</div>
            <div class="text-10 leading-11 mb-line-11">
              <div>${additionalInfo}</div>
            </div>     
          `}

          <div class="font-bold text-8 leading-11">
            ${showBlanks ? lang.debtorFieldHeading : lang.debtorHeading}
          </div>
          ${showBlanks ? blankFieldSVG(65, 25, { marginTop: '1.1pt' }) : html`
            <div class="text-10 leading-11">
              <div>${debtorFullName}</div>
              ${!reduceContent && html`<div>${debtorStreetPlot}</div>`}
              <div>${debtorPostcodeLocality}</div>
            </div>
          `}
        </div>

      </div>
      <div class="h-10"></div>
    </div>

  `.style(styles)
}



define(AQRBill)