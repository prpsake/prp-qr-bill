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
  lang: property(translate),
  iban: property(blockString(4)),

  render: ({

    lang,
    iban

  }) => html`

    <div class="flex flex-col w-62 p-5 border-r">

      <div class="h-7 font-bold text-11 leading-none">${lang.receiptTitle}</div>

      <div class="h-56">
        <div class="font-bold text-6 leading-9">${lang.creditorHeading}</div>
        <div class="text-8 leading-9 mb-line-9">
          <div>${iban}</div>
        </div>

        <div class="font-bold text-6 leading-9">${lang.referenceHeading}</div>
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