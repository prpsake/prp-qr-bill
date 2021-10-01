import { property } from 'hybrids'



// Detector/Validator

const isEmpty =
  xs =>
  !Array.isArray(xs) ||
  xs.length === 0 ||
  xs.some(
    x => 
    (typeof x !== 'number' && typeof x !== 'string') || x === ''
  )



const detectAddressType = 
  address =>
  isEmpty([address.streetNumber, address.postalCode]) ? "K" : "S"



// Helpers

const parseData =
  x => {
    if (x === undefined) return {}
    try {
      const data = JSON.parse(x)
      
      return data
    } catch (e) {
      console.log(e)
      return {}
    }
  }



// Factories

const setPropsFromData =
  () =>
  ({
    ...property(parseData),
    connect: (host, key) => {
      const data = host[key]

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

      host.additionalInfo = data.additionalInfo
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