module.exports = {
  darkMode: 'class',
  content: ["./site/**/*.{html,md}", "elm/**/*.elm"],
  theme: {
      fontFamily: {
          'serif': ['Spectral', 'serif'],
          'mono': ['"Source Code Pro"', 'mono'],
          'sans': ['"Montserrat"', 'sans-serif']
      },
      extend: {
      },
  },
  variants: {
    extend: {
      display: ['dark']
    }
  },
  plugins: [
    require('@tailwindcss/forms')
  ],
}
