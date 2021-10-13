import { property } from 'hybrids'
import * as Parser from './Parser.bs.js'
import * as Validator from './Validator.bs.js'



const setPropsFromData =
  () =>
  ({
    ...property(Parser.parseJson),
    connect: (host, key) => {
      Validator
      .validateEntries(host[key])
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