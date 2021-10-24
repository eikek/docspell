// tailwind.config.js

const colors = require('tailwindcss/colors')

module.exports = {
    variants: {
        extend: {
            backgroundOpacity: ['dark']
        }
    },
    purge: false,
    darkMode: 'class', // or 'media' or 'class'
    theme: {
        extend: {
            colors: {
                bluegray: colors.blueGray,
                warmgray: colors.warmGray,
                amber: colors.amber,
                orange: colors.orange,
                teal: colors.teal,
                lime: colors.lime,
                lightblue: colors.sky
            }
        }
    },
    plugins: [
        require('@tailwindcss/forms')
    ]
//    prefix: 'tw-'
}
