import js from "@eslint/js";
import globals from "globals";
import tseslint from "typescript-eslint";
import pluginReact from "eslint-plugin-react";
import css from "@eslint/css";
import { defineConfig } from "eslint/config";
import stylistic from "@stylistic/eslint-plugin";
import jsdoc from "eslint-plugin-jsdoc";

export default defineConfig([
    { settings: { react: { version: "detect" } } },
    { ignores: ["*.cjs", "eslint.config.mjs", "**/public/**", "**/node_modules/**", "**/cypress/**", "cypress.config.ts", ".stylelintrc.js", "src/frontend/testing/**", "src/frontend/css/stylesheets/external/**", "src/frontend/components/dashboard/lib/react/polyfills/**", "babel.config.js", "webpack.config.js", "jest.config.js", "tsconfig.json", "src/frontend/js/lib/jqplot/**", "src/frontend/js/lib/jquery/**", "src/frontend/js/lib/plotly/**", "src/frontend/components/timeline/**", "fengari-web.js"] },
    { files: ["**/*.{js,mjs,cjs,ts,mts,cts,jsx,tsx}"], plugins: { js }, extends: ["js/recommended"] },
    { files: ["**/*.{js,mjs,cjs,ts,mts,cts,jsx,tsx}"], languageOptions: { globals: { ...globals.browser, ...globals.jquery, ...globals.jest } } },
    tseslint.configs.recommended,
    pluginReact.configs.flat.recommended,
    { files: ["**/*.css"], plugins: { css }, language: "css/css", extends: ["css/recommended"] },
    { plugins: {'@stylistic': stylistic, jsdoc} },
    {
        rules: {
            "@typescript-eslint/no-explicit-any": "off",
            'react/prop-types': 'off',
            'react/no-deprecated': 'off', // We are currently using deprecated React features, so we disable this rule - this will change in the future
            '@stylistic/quotes': ['error', 'single'],
            '@stylistic/no-extra-semi': 'error',
            '@stylistic/semi': ['error', 'always'],
            '@stylistic/curly-newline': 'error',
            '@stylistic/newline-per-chained-call': 'error',
            '@stylistic/indent': ['error', 4],
            '@stylistic/comma-dangle': ['error', 'never'],
            "jsdoc/require-jsdoc": [
                "error",
                {
                    require: {
                        FunctionDeclaration: true,
                        MethodDefinition: true,
                        ClassDeclaration: true,
                        ArrowFunctionExpression: false,
                        FunctionExpression: false
                    }
                }
            ],
        }
    }
]);
