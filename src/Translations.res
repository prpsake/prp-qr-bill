type lang =
  [
    #en
  | #de
  | #fr
  | #it
  ]



type translation =
  {
    paymentPartTitle: string,
    creditorHeading: string,
    referenceHeading: string,
    additionalInfoHeading: string,
    furtherInfoHeading: string,
    currencyHeading: string,
    amountHeading: string,
    receiptTitle: string,
    acceptancePointHeading: string,
    separateText: string,
    debtorHeading: string,
    debtorFieldHeading: string,
    ultimateCreditorHeading: string
  }



let translations =
 {
   "en": {
    paymentPartTitle: "Payment part",
    creditorHeading: "Account / Payable to",
    referenceHeading: "Reference",
    additionalInfoHeading: "Additional information",
    furtherInfoHeading: "Further information",
    currencyHeading: "Currency",
    amountHeading: "Amount",
    receiptTitle: "Receipt",
    acceptancePointHeading: "Acceptance point",
    separateText: "Separate before paying in",
    debtorHeading: "Payable by",
    debtorFieldHeading: "Payable by (name/address)",
    ultimateCreditorHeading: "In favour of"
  },
  "de": {
    paymentPartTitle: "Zahlteil",
    creditorHeading: "Konto / Zahlbar an",
    referenceHeading: "Referenz",
    additionalInfoHeading: "Zusätzliche Informationen",
    furtherInfoHeading: "Weitere Informationen",
    currencyHeading: "Währung",
    amountHeading: "Betrag",
    receiptTitle: "Empfangsschein",
    acceptancePointHeading: "Annahmestelle",
    separateText: "Vor der Einzahlung abzutrennen",
    debtorHeading: "Zahlbar durch",
    debtorFieldHeading: "Zahlbar durch (Name/Adresse)",
    ultimateCreditorHeading: "Zugunsten"
  },
  "fr": {
    paymentPartTitle: "Section paiement",
    creditorHeading: "Compte / Payable à",
    referenceHeading: "Référence",
    additionalInfoHeading: "Informations supplémentaires",
    furtherInfoHeading: "Informations additionnelles",
    currencyHeading: "Monnaie",
    amountHeading: "Montant",
    receiptTitle: "Récépissé",
    acceptancePointHeading: "Point de dépôt",
    separateText: "A détacher avant le versement",
    debtorHeading: "Payable par",
    debtorFieldHeading: "Payable par (nom/adresse)",
    ultimateCreditorHeading: "En faveur de"
  },
  "it": {
    paymentPartTitle: "Sezione pagamento",
    creditorHeading: "Conto / Pagabile a",
    referenceHeading: "Riferimento",
    additionalInfoHeading: "Informazioni supplementari",
    furtherInfoHeading: "Informazioni aggiuntive",
    currencyHeading: "Valuta",
    amountHeading: "Importo",
    receiptTitle: "Ricevuta",
    acceptancePointHeading: "Punto di accettazione",
    separateText: "Da staccare prima del versamento",
    debtorHeading: "Pagabile da",
    debtorFieldHeading: "Pagabile da (nome/indirizzo)",
    ultimateCreditorHeading: "A favore di"
  }
}



let translate: lang => translation =
  lang =>
  switch lang {
  | #en => translations["en"]
  | #de => translations["de"]
  | #fr => translations["fr"]
  | #it => translations["it"]
  }