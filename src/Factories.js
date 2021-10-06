import { property } from 'hybrids'
import { Parser } from './Parser.bs.js'
import { Validator } from './Validator.bs.js'



const setPropsFromData =
  () =>
  ({
    ...property(Parser.parseJson),
    connect: (host, key) => {
      const entries = host[key]
      console.log(Validator.validate(entries))
      // optionally validate...
      entries.forEach(([k, v]) => host[k] = v)
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