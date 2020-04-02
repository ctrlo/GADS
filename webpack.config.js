const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const { resolve } = require('path');

module.exports = {
  mode: 'production',
  entry: {
    dashboard: './src/dashboard/index.tsx'
  },
  output: {
    filename: 'js/[name].js',
    path: resolve(__dirname, './public'),
  },
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        loader: 'awesome-typescript-loader',
      },
      {
        test: /\.scss$/,
        loader: [
          {
            loader: MiniCssExtractPlugin.loader,
          },
          'css-loader',
          {
            loader: 'sass-loader',
            options: {
              sourceMap: true
            }
          }
        ]
      }
    ],
  },
  resolve: {
    extensions: ['.ts', '.tsx', '.js', '.json', '.scss'],
  },
  devtool: 'source-map',
  plugins: [
    new MiniCssExtractPlugin({
      filename: 'css/dashboard.css',
    })
  ],
  watchOptions: {
    ignored: /node_modules/,
    poll: 1000
  }
};
