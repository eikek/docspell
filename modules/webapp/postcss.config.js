//postcss.config.js

const basePlugins =
      [
          require('postcss-import'),
          require('tailwindcss'),
          require('autoprefixer'),
      ];

const prodPlugins =
      [
          require('postcss-import'),
          require('tailwindcss'),
          require('autoprefixer'),
          require('cssnano'),
      ];


module.exports = (ctx) => ({
    plugins: ctx && ctx.env === 'production' ? prodPlugins : basePlugins
})
