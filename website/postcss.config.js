//postcss.config.js

module.exports = (ctx) => ({
    plugins: [
        require('postcss-import'),
        require('tailwindcss'),
        require('autoprefixer'),
        require('cssnano'),
    ]
})
