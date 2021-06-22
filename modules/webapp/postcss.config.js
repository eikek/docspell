//postcss.config.js
const tailwindcss = require("tailwindcss");

const devPlugins =
      [
          require('postcss-import'),
          tailwindcss("./tailwind.config.js"),
          require("autoprefixer")
      ];

const prodPlugins =
      [
          require('postcss-import'),
          tailwindcss("./tailwind.config.js"),
          require("autoprefixer"),
          require("@fullhuman/postcss-purgecss")({
              content: [
                  "./src/main/elm/**/*.elm",
                  "./src/main/styles/keep.txt",
                  "../restserver/src/main/templates/*.html"
              ],
              defaultExtractor: content => content.match(/[A-Za-z0-9-_:/\.]+/g) || []
          }),
          require('cssnano')({
              preset: 'default'
          })
      ]

module.exports = (ctx) => ({
    plugins: ctx.env === 'production' ? prodPlugins : devPlugins
});
