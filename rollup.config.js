import multi from '@rollup/plugin-multi-entry';
import babel from 'rollup-plugin-babel';

export default {
  input: [
    'src/polyfills/*.js',
    'src/template/index.js'
  ],
  output: {
    file: 'public/js/template.js',
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
