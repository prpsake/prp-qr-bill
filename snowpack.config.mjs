import execa from 'execa'


const mode = process.env.NODE_ENV


export default {
  mount: {
    src: '/',
    public: { url: '/', static: true, resolve: false },
  },
  routes: [
    {
      match: 'routes',
      src: '/',
      dest: '/demo/index.html',
    },
    {
      match: 'all',
      src: '/favicon.ico',
      dest: '/demo/favicon.ico',
    },
  ],
  exclude: ['**/*.res', '**/*.resi', '**/etc/**/*'],
  devOptions: {},
  buildOptions: {
    out: 'dist',
    metaUrlPath: 'lib',
  },
  packageOptions: {
    external: mode === "production" ? ['hybrids'] : [],
  },
  plugins: [
    ['@ampire/snowpack-plugin-plugin', {
      input: ['.css'],
      output: ['.js'],
      load: async ({ isDev, filePath }) => {
        const cmd = await execa.command(`postcss ${filePath}`)
        let stdout = cmd.stdout
        if (!isDev) {
          stdout = 
          stdout
          .replace(/(\/\*[\s\S]+\*\/|\n)/g, ' ')
          .replace(/\s{2,}/g, ' ')
        }
        return `export default ${JSON.stringify(stdout)}`
      }
    }]
  ],
  optimize: {
    entrypoints: ['src/index.js'],
    target: 'es2020',
  },
}