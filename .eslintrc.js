module.exports = {
  env: {
    browser: true,
    es6: true,
    jquery: true
  },
  

  globals: {
    // Linkspace associated globals
    'Linkspace': 'readonly',
    'setupCalculator': 'readonly',
    'SelectWidget': 'readonly',
    'setupSelectWidgets': 'readonly',
    'setupLessMoreWidgets': 'readonly',
    'getFieldValues': 'readonly',
    'setupFileUpload': 'readonly',
    'setupDependentField': 'readonly',
    'setupDependentFields': 'readonly',
    'setupTreeField': 'readonly',
    'setupTreeFields': 'readonly',
    'positionDisclosure': 'readonly',
    'onDisclosureClick': 'readonly',
    'onDisclosureMouseover': 'readonly',
    'onDisclosureMouseout': 'readonly',
    'toggleDisclosure': 'readonly',
    'setupDisclosureWidgets': 'readonly',
    'runPageSpecificCode': 'readonly',
    'setupClickToEdit': 'readonly',
    'setupSubmitListener': 'readonly',
    'setupClickToViewBlank': 'readonly',
    'setFirstInputFocus': 'readonly',
    'setupRecordPopup': 'readonly',
    'setupAccessibility': 'readonly',
    'getParams': 'readonly',
    'setupColumnFilters': 'readonly',
    'setupHtmlEditor': 'readonly',
    'setupTimeline': 'readonly',
    'setupOtherUserViews': 'readonly',
    // builder
    'UpdateFilter': 'readonly',
    // Other libraries
    'FontDetect': 'readonly',
    'Plotly': 'readonly',
    'base64': 'readonly',
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
    'prettier/prettier': 'error',
    'jsdoc/require-param-description': 0,
    'jsdoc/require-returns-description': 0,
  },
};

