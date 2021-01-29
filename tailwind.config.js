// tailwind.config.js

const colors = require('tailwindcss/colors')

module.exports = {
    purge: false,
    darkMode: 'class', // or 'media' or 'class'
    theme: {
        extend: {
            colors: {
                bluegray: colors.blueGray,
                amber: colors.amber,
                teal: colors.teal
            }
        }
    },
    variants: {},
    plugins: [
    ]
//    prefix: 'tw-'
}
