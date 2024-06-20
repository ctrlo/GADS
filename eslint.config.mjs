import { fixupConfigRules, fixupPluginRules } from "@eslint/compat";
import typescriptEslint from "@typescript-eslint/eslint-plugin";
import react from "eslint-plugin-react";
import globals from "globals";
import tsParser from "@typescript-eslint/parser";
import path from "node:path";
import { fileURLToPath } from "node:url";
import js from "@eslint/js";
import { FlatCompat } from "@eslint/eslintrc";
import stylistic from "@stylistic/eslint-plugin-js"

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
    baseDirectory: __dirname,
    recommendedConfig: js.configs.recommended,
    allConfig: js.configs.all
});

export default [{
    ignores: [
        "**/public",
        "src/frontend/components/dashboard/lib/react/polyfills",
        "**/babel.config.js",
        "**/webpack.config.js",
        "**/jest.config.js",
        "**/tsconfig.json",
        "src/frontend/js/lib/jqplot",
        "src/frontend/js/lib/jquery",
        "src/frontend/js/lib/plotly",
        "src/frontend/components/timeline",
        "**/fengari-web.js",
    ],
}, ...fixupConfigRules(compat.extends(
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:react/recommended",
)), {
    plugins: {
        "@typescript-eslint": fixupPluginRules(typescriptEslint),
        react: fixupPluginRules(react),
        "stylisticjs": stylistic,
    },

    languageOptions: {
        globals: {
            ...globals.browser,
            ...globals.jest,
            ...globals.jquery,
        },

        parser: tsParser,
        sourceType: "module",
    },

    settings: {
        react: {
            version: "detect",
        },
    },

    rules: {
        "react/prop-types": 0,
        "@typescript-eslint/no-explicit-any": 0,
        "no-prototype-builtins": 0,
        "@typescript-eslint/ban-types": 0,
        "stylisticjs/semi": 2,
    },
}, {
    files: ["**/.eslintrc.{js,cjs}"],

    languageOptions: {
        globals: {
            ...globals.node,
        },

        ecmaVersion: 5,
        sourceType: "commonjs",
    },
}];