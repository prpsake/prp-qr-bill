import { promises as fs } from 'fs'


export default {
  mount: {
    src: '/_dist',
    public: '/',
  },
  devOptions: {},
  plugins: [
    ['@ampire/snowpack-plugin-plugin', {
      input: ['.css'],
      output: ['.js'],
      load: async ({ isDev, filePath}) => {
        const content = await fs.readFile(filePath, 'utf8')
        return `export default ${JSON.stringify(content)}`
      }
    }]
  ],
}