const fromRange =
  (unit, step, max) =>
  Object
  .fromEntries(
    [...Array(Math.floor(max/step)).keys()]
    .map(x => [`${(x+1) * step}`, `${(x+1)}${unit}`])
  )


const fromArray =
  (unit, arr) =>
  Object
  .fromEntries(
    arr
    .map(x => [`${x}`, `${x}${unit}`])
  )


module.exports = {
  //mode: 'jit',
  purge: ['./src/**/*.js'],
  darkMode: false, // or 'media' or 'class'
  corePlugins: [
    'flex',
    'width',
    'height',
    'margin',
    'padding',
    'backgroundColor',
    'borderColor',
    'borderWidth',
    'borderStyle',
    'textColor',
    'lineHeight',
    'fontSize',
    'fontWeight',
  ],
  theme: {
    screens: {
      'print': {'raw': 'print'},
    },
    spacing: {
      '5': '5mm'
    },
    width: fromArray('mm', [210, 148, 92, 87, 62, 52, 51, 46]),
    height: fromArray('mm', [105, 95, 56, 46, 22, 18, 14, 10, 7]),
    colors: {
      black: '#000',
      white: '#fff',
    },
    borderWidth: {
      DEFAULT: '1pt'
    },
    lineHeight: fromArray('pt', [8, 9, 11, 13]),
    fontSize: fromArray('pt', [6, 7, 8, 10, 11]),
    fontWeight: {
      normal: '400',
      bold: '700',
    }
  },
  variants: {},
  plugins: [],
}
