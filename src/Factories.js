const setBoolFromVersions =
  versions =>
  ({
    connect: (host, key) => {
       host[key] = versions.some(x => x === host.version)
    }
  })



export { setBoolFromVersions }