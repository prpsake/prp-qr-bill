const isObject =
  x =>
  Boolean(x?.constructor) && Object.is(x.constructor, Object)



// any of (any v of k1 OR any v of k2 OR ...)
const showWith = 
  otherKeys =>
  ({
    connect: (host, key) => {
      host[key] =
      isObject(otherKeys) ?
      Object.entries(otherKeys).map(
        ([k, vs]) =>
        Array.isArray(vs) ?
        vs.some(v => v === host[k]) :
        false
      ).some(x => x) :
      false
    }
  })



// any of (every v of k1 OR every v of k2 OR ... )
const notShowWith =
  otherKeys =>
  ({
    connect: (host, key) => {
      host[key] =
      isObject(otherKeys) ?
      Object.entries(otherKeys).map(
        ([k, vs]) =>
        Array.isArray(vs) ?
        vs.every(v => v !== host[k]) :
        true
      ).some(x => x) :
      true
    }
  })



export { showWith, notShowWith }