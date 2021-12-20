import { execaCommand } from "execa"


const mode = process.env.NODE_ENV


export default {
  mount: {
    src: "/",
    public: { url: "/", static: true, resolve: true },
  },
  routes: [
    {
      match: "routes",
      src: "/",
      dest: "/demo/demo.html",
    },
    {
      match: "all",
      src: "/demo.js",
      dest: "/demo/demo.js",
    },
    {
      match: "all",
      src: "/demo.json",
      dest: "/demo/demo.json",
    },
    {
      match: "all",
      src: "/favicon.ico",
      dest: "/demo/favicon.ico",
    },
  ],
  exclude: ["**/*.res", "**/*.resi", "**/etc/**/*", "**/demo/**/*"],
  devOptions: {},
  buildOptions: {
    out: "dist",
    metaUrlPath: "lib",
  },
  packageOptions: {
    external: mode === "production" ? ["hybrids"] : [],
  },
  plugins: [
    ["@gourmetseasoningsake/snowpack-plugin-plugin", {
      input: [".css"],
      output: [".js"],
      config: x => {
        return x
      },
      load: async ({ isDev, filePath }) => {
        const cmd = await execaCommand(`postcss ${filePath}`)
        let stdout = cmd.stdout
        if (!isDev) {
          stdout = 
          stdout
          .replace(/(\/\*[\s\S]+\*\/|\n)/g, " ")
          .replace(/\s{2,}/g, " ")
        }
        return `export default ${JSON.stringify(stdout)}`
      }
    }]
  ],
  optimize: {
    entrypoints: ["src/index.js"],
    target: "es2020",
  },
}