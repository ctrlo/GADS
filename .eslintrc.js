module.exports = {
  env: {
    browser: true,
    es6: true,
    jquery: true
  },


  globals: {
    // Linkspace associated globals
    'Linkspace': 'readonly',
    // builder
    'UpdateFilter': 'readonly',
    // Other libraries
    '_': 'readonly',
    'FontDetect': 'readonly',
    'Handlebars': 'readonly',
    'Plotly': 'readonly',
    'base64': 'readonly',
    'moment': 'readonly',
    'timeline': 'readonly',
    'tippy': 'readonly',
    'vis': 'readonly',
  },

  plugins: ['prettier', 'jsdoc'],

  parserOptions: {
    ecmaVersion: 6,
    ecmaFeatures: {
      experimentalObjectRestSpread: true
    },
    sourceType: "module",
  },

  extends: ['problems', 'prettier', 'plugin:jsdoc/recommended'],

  rules: {
    // Legacy-related disables:
    'no-var': 0,
    'eqeqeq': 0,
    'prefer-arrow-callback': 0,
    'prefer-template': 0,
    'prefer-rest-params': 0,
    'prefer-spread': 0,
    'strict': 0,
    'object-shorthand': 0,
    'dot-notation': 0,
    'prettier/prettier': 0,
    'jsdoc/require-param-description': 0,
    'jsdoc/require-returns-description': 0,
    'no-unused-vars': 0,
    'no-undef': 0,
  },
};
