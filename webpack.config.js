const path = require('path')
const webpack = require('webpack')
const autoprefixer = require('autoprefixer')
const sass = require('sass')
const TerserPlugin = require('terser-webpack-plugin')
const { CleanWebpackPlugin } = require('clean-webpack-plugin')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const CopyWebpackPlugin = require('copy-webpack-plugin')

const plugins = [
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    Buffer: ['buffer', 'Buffer'],
  }),
  new MiniCssExtractPlugin({
    filename: '[name].css',
  }),
  new CleanWebpackPlugin(),
  new CopyWebpackPlugin({
    patterns: [
      {
        from: 'node_modules/summernote/dist/font',
        to: '../css/font'
      },
      {
        from: '*.json',
        context: path.resolve(__dirname, "src", "frontend", "js", "lib", "plotly"),
      }
    ]
  }),
]

module.exports = (env) => {
  return {
    mode: env.development ? 'development' : 'production',
    devtool: env.development ? 'source-map' : false,
    entry: {
      site: path.resolve(__dirname, './src/frontend/js/site.js'),
      '../css/general': path.resolve(__dirname, './src/frontend/css/stylesheets/general.scss'),
      '../css/external': path.resolve(__dirname, './src/frontend/css/stylesheets/external.scss'),
    },

    module: {
      rules: [
        {
          test: /\.js$/,
          exclude: [/node_modules/, /\.test\.js$/, /test/],
          use: ['babel-loader']
        },
        {
          test: /\.tsx?$/,
          exclude: [/node_modules/, /\.test\.tsx?$/, /test/],
          use: ['babel-loader', 'ts-loader']
        },
        {
          test: /\.(gif|jpg|png|svg|eot|ttf|woff|woff2)$/,
          type: 'asset',
        },
        {
          test: /\.(scss|css)$/,
          use: [
            {
              loader: MiniCssExtractPlugin.loader,
            },
            {
              loader: 'css-loader',
              options: {
                importLoaders: 2,
                sourceMap: false,
                modules: false,
              },
            },
            {
              loader: 'postcss-loader',
              options: {
                plugins: [autoprefixer],
              },
            },
            {
              loader: 'sass-loader',
              options: {
                implementation: sass,
                sassOptions: {
                  includePaths: ['src/frontend/components'],
                },
              },
            },
          ],
        },
      ],
    },

    optimization: {
      minimize: env.development ? false : true,
      minimizer: [
        new TerserPlugin({
          terserOptions: {
            format: {
              comments: false,
            },
          },
          extractComments: false,
        }),
      ],
    },

    output: {
      filename: '[name].js',
      path: path.resolve(__dirname, 'public/js'),
      chunkFilename: '[name].[chunkhash].js',
    },

    plugins,

    resolve: {
      alias: {
        components: path.resolve(__dirname, 'src/frontend/components'),
        jQuery: path.resolve(__dirname, 'node_modules/jquery/dist/jquery.js'),
        'jquery-ui/ui/widget': 'blueimp-file-upload/js/vendor/jquery.ui.widget.js',
      },
      extensions: ['.tsx', '.ts', '.jsx', '.js'],
      fallback: {
        'fs': false,
        'buffer': require.resolve('buffer'),
      },
      modules: [
        path.resolve(__dirname, 'src/frontend/js/lib'),
        path.resolve(__dirname, 'node_modules'),
      ],
    },

    target: 'web',
  }
};
