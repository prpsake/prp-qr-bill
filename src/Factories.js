import { property } from 'hybrids'
import { Parser } from './Parser.bs.js'



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
    ...property(Parser.parseJson),
    connect: (host, key) => {
      Object
      .entries(host[key])
      .forEach(([k, v]) => host[k] = v)
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