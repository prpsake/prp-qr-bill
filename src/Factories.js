import { property } from 'hybrids'
import { parseJson } from './Helpers.bs.js'



// Detector/Validator

const isEmpty =
  x => 
  (typeof x !== 'number' && typeof x !== 'string') || x === ''



const someEmpty =
  xs =>
  !Array.isArray(xs) ||
  xs.length === 0 ||
  xs.some(isEmpty)



const detectAddressType = 
  address =>
  someEmpty([address.streetNumber, address.postalCode]) ? "K" : "S"



// Factories

const setPropsFromData =
  () =>
  ({
    ...property(parseJson),
    connect: (host, key) => {
      const data = host[key]
      console.log(data)
      // optionally validate
      // ...

      host.lang = data.lang

      host.currency = data.currency
      host.amount = data.amount
      host.iban = data.iban
      host.reference = data.reference

      host.creditorAddressType = detectAddressType(data.creditor)
      host.creditorName = data.creditor.name
      host.creditorStreet = data.creditor.street
      host.creditorStreetNumber = data.creditor.streetNumber
      host.creditorPostOfficeBox = data.creditor.postOfficeBox
      host.creditorPostalCode = data.creditor.postalCode
      host.creditorLocality = data.creditor.locality
      host.creditorCountryCode = data.creditor.countryCode

      host.debtorAddressType = detectAddressType(data.debtor)
      host.debtorName = data.debtor.name
      host.debtorStreet = data.debtor.street
      host.debtorStreetNumber = data.debtor.streetNumber
      host.debtorPostOfficeBox = data.debtor.postOfficeBox
      host.debtorPostalCode = data.debtor.postalCode
      host.debtorLocality = data.debtor.locality
      host.debtorCountryCode = data.debtor.countryCode

      host.additionalInfoMessage = data.additionalInfo.message
      host.additionalInfoCode = data.additionalInfo.code
    }
  })



const setBoolFromVersions =
  versions =>
  ({
    connect: (host, key) => {
       host[key] = versions.some(x => x === host.version)
    }
  })



export { setPropsFromData, setBoolFromVersions }