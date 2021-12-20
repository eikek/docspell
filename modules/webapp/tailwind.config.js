// tailwind.config.js

const colors = require('tailwindcss/colors')

module.exports = {
    darkMode: 'class', // or 'media' or 'class'
    content: [ "./src/main/elm/**/*.elm",
               "./src/main/styles/keep.txt",
               "../restserver/src/main/templates/*.html"
             ],
    variants: {
        extend: {
            backgroundOpacity: ['dark']
        }
    },
    purge: false,
    plugins: [
        require('@tailwindcss/forms')
    ]
//    prefix: 'tw-'
}
