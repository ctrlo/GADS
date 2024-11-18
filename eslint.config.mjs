import globals from "globals";
import pluginJs from "@eslint/js";
import tseslint from "typescript-eslint";
import pluginReact from "eslint-plugin-react";
import stylistic from "@stylistic/eslint-plugin";

/** @type {import('eslint').Linter.Config[]} */
export default [
  {
    plugins: {
      "@stylistic": stylistic,
    }
  },
  {
    settings: {
      react: {
        version: "detect"
      }
    }
  },
  {
    ignores: ["public",
      "src/frontend/components/dashboard/lib/react/polyfills",
      "babel.config.js",
      "webpack.config.js",
      "jest.config.js",
      "tsconfig.json",
      "src/frontend/js/lib/jqplot",
      "src/frontend/js/lib/jquery",
      "src/frontend/js/lib/plotly",
      "src/frontend/components/timeline",
      "fengari-web.js",
      "cypress.config.ts",
      "cypress",
    ]
  },
  { files: ["./src/**/*.{js,mjs,cjs,ts,jsx,tsx}"] },
  { languageOptions: { globals: { ...globals.browser, ...globals.jest, ...globals.jquery } } },
  pluginJs.configs.recommended,
  ...tseslint.configs.recommended,
  pluginReact.configs.flat.recommended,
  {
    rules: {
      "@typescript-eslint/no-explicit-any": "off",
      "@typescript-eslint/no-unused-expressions": "off",
      "react/prop-types": "off",
      "@stylistic/semi": ["error", "always"],
      "@typescript-eslint/no-this-alias": "off",
    }
  }
];