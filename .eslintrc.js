module.exports = {
  "env": {
    "browser": true,
    "es6": true,
    "jest": true,
    "jquery": true,
  },
  "settings": {
    "react": {
      "version": "detect"
    }
  },
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:react/recommended"
  ],
  "overrides": [
    {
      "env": {
        "node": true,
      },
      "files": [
        ".eslintrc.{js,cjs}"
      ],
      "parserOptions": {
        "sourceType": "script"
      }
    }
  ],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": "es6",
    "sourceType": "module"
  },
  "plugins": [
    "@typescript-eslint",
    "react"
  ],
  "rules": {
    "react/prop-types": 0,
    "@typescript-eslint/no-explicit-any": 0,
    "no-prototype-builtins": 0,
    "@typescript-eslint/ban-types": 0,
  }
};
