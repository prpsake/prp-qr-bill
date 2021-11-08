import execa from 'execa'


export default {
  mount: {
    src: '/dist',
    public: '/',
  },
  devOptions: {},
  plugins: [
    ['@ampire/snowpack-plugin-plugin', {
      input: ['.css'],
      output: ['.js'],
      load: async ({ isDev, filePath}) => {
        const cmd = await execa.command(`postcss ${filePath}`)
        return `export default ${JSON.stringify(cmd.stdout)}`
      }
    }]
  ],
  optimize: {
    bundle: true,
    minify: true,
    target: 'es2018',
  },
}