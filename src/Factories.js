const showWith =
  (otherKey, values) =>
  ({
    connect: (host, key) => {
      host[key] = values.some(x => x === host[otherKey])
    }
  })



export { showWith }