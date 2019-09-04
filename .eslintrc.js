module.exports = {
  env: {
    browser: true,
    es6: true
  },

  plugins: ['prettier', 'jsdoc'],

  parserOptions: {
    ecmaVersion: 6,
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
    'prettier/prettier': ['error', require('./package.json').prettier],
    'jsdoc/require-param-description': 0,
    'jsdoc/require-returns-description': 0,
  },
};

