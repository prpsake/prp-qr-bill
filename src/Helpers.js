const isObject =
  x =>
  Boolean(x?.constructor) && Object.is(x.constructor, Object)



const isTrueish = 
  x => 
  typeof x === 'number' || x



// any of (any v of k1 OR any v of k2 OR ...)
const showWith = 
  (host, otherKeys) =>
  isObject(otherKeys) ?
  Object.entries(otherKeys).map(
    ([k, vs]) =>
    Array.isArray(vs) ?
    vs.some(v => v === host[k]) :
    false
  ).some(isTrueish) :
  false



// any of (every v of k1 OR every v of k2 OR ... )
const notShowWith =
  (host, otherKeys) =>
  isObject(otherKeys) ?
  Object.entries(otherKeys).map(
    ([k, vs]) =>
    Array.isArray(vs) ?
    vs.every(v => v !== host[k]) :
    true
  ).some(isTrueish) :
  true



const fn = f => ({ set: (_, value) => f(value) })



export { showWith, notShowWith, fn }