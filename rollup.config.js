import resolve from '@rollup/plugin-node-resolve';
import babel from 'rollup-plugin-babel';
import commonjs from 'rollup-plugin-commonjs';

export default {
  input: 'src/template/index.js',
  output: {
    file: 'public/js/template.js',
    format: 'iife'
  },
  plugins: [
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
    resolve(),
    commonjs(),
  ]
};
