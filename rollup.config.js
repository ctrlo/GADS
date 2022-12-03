import multi from '@rollup/plugin-multi-entry';
import babel from 'rollup-plugin-babel';
import { uglify } from "rollup-plugin-uglify";

export default {
  input: [
    'src/polyfills/*.js',
    'src/patches/*.js',
    'src/linkspace.js'
  ],
  output: {
    file: 'public/js/linkspace.js',
    format: 'iife'
  },
  plugins: [
    multi({
      exports: false
    }),
    babel({
      babelrc: false,
      exclude: 'node_modules/**',
      presets: [
        [
          '@babel/preset-env',
          {
            corejs: 3,
            modules: false,
            useBuiltIns: 'usage',
            targets: 'ie 8, last 3 version',
          },
        ],
      ],
    }),
  ]
};
