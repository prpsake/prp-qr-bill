import execa from 'execa'


const mode = process.env.NODE_ENV


export default {
  mount: {
    src: '/',
    public: { url: '/', static: true, resolve: true },
  },
  routes: [
    {
      match: 'routes',
      src: '/',
      dest: '/demo/demo1.html',
    },
    {
      match: 'routes',
      src: '/demo2',
      dest: '/demo/demo2.html',
    },
    {
      match: 'all',
      src: '/demo1.js',
      dest: '/demo/demo1.js',
    },
    {
      match: 'all',
      src: '/demo2.js',
      dest: '/demo/demo2.js',
    },
    {
      match: 'all',
      src: '/demo2.json',
      dest: '/demo/demo2.json',
    },
    {
      match: 'all',
      src: '/favicon.ico',
      dest: '/demo/favicon.ico',
    },
  ],
  exclude: ['**/*.res', '**/*.resi', '**/etc/**/*', '**/demo/**/*'],
  devOptions: {},
  buildOptions: {
    out: 'dist',
    metaUrlPath: 'lib',
  },
  packageOptions: {
    external: mode === "production" ? ['hybrids'] : [],
  },
  plugins: [
    ['@gourmetseasoningsake/snowpack-plugin-plugin', {
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