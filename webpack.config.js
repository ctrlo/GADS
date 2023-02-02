const path = require('path')
const webpack = require('webpack')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const StyleLintPlugin = require('stylelint-webpack-plugin')
const CopyWebpackPlugin = require('copy-webpack-plugin')

// Variables from environment
const isDevelopment = process.env.NODE_ENV === 'dev'

// Plugins to use in Webpack
const plugins = [
  new MiniCssExtractPlugin({
    filename: '[name].css',
  }),
  new StyleLintPlugin({
    fix: false,
    syntax: 'scss',
  }),
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery'
  }),
  new CopyWebpackPlugin({
    patterns: [{
      from: 'node_modules/summernote/dist/font',
      to: 'css/font'
    }]
  }),
]

module.exports = {
  devServer: {
    contentBase: path.resolve(__dirname, 'html'),
    headers: {
      // Used for loading fonts cross domains
      // Webpack serves from an other port than Roger
      'Access-Control-Allow-Origin': '*',
    },
  },

  entry: {
    site: './src/frontend/js/site.js',
    'css/general': './src/frontend/css/stylesheets/general.scss',
    'css/external': './src/frontend/css/stylesheets/external.scss',
  },

  mode: isDevelopment ? 'development' : 'production',

  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: [
          {
            loader: 'babel-loader',
            options: {
              'sourceType': 'unambiguous',
              'presets': [
                [
                  '@babel/preset-env',
                  {
                    corejs: 3,
                    useBuiltIns: 'usage',
                    targets: {
                      'edge': '17',
                      'firefox': '60',
                      'chrome': '67',
                      'safari': '11.1',
                      'ie': '11'
                    },
                  },
                ],
                '@babel/preset-react',
              ]
            }
          },
        ],
      },

      {
        test: /\.(jpg|png|svg|eot|ttf|woff|woff2?)$/,
        use: [
          {
            loader: 'url-loader',
            options: {
              limit: 500, // Inline everything below 500 bytes,
              outputPath: p => `/${p}`,
              name: '[path][name].[ext]',
              context: path.resolve(__dirname, 'html'),
              emitFile: false,
            },
          },
        ],
      },

      {
        test: /\.(scss|css)$/,
        use: [
          {
            loader: MiniCssExtractPlugin.loader,
            options: {
              hmr: isDevelopment,
            },
          },
          {
            loader: 'css-loader',
            options: {
              url: false,
            },
          },
          {
            loader: 'postcss-loader',
            options: {
              plugins: [require('autoprefixer')],
              sourceMap: isDevelopment,
            },
          },
          {
            loader: 'sass-loader',
            options: {
              implementation: require('sass'),
              sassOptions: {
                includePaths: ['src/frontend/components'],
              },
              prependData: `$is-development: ${isDevelopment};`,
            },
          },
        ],
      },

      {
        test: /\.tsx?$/,
        use: ['babel-loader', 'ts-loader'],
        exclude: /node_modules/
      },
    ],
  },

  output: {
    filename: '[name].js',
    chunkFilename: '[id].[name].js',
    path: path.resolve(__dirname, 'public', 'js'),
    publicPath: '/js/'
  },

  plugins,

  resolve: {
    alias: {
      components: path.resolve(__dirname, 'src', 'frontend', 'components'),
      jQuery: path.resolve(__dirname, 'node_modules/jquery/dist/jquery.js'),
      'jquery-ui/ui/widget': 'blueimp-file-upload/js/vendor/jquery.ui.widget.js'
    },
    extensions: ['.tsx', '.ts', '.jsx', '.js'],
    modules: [
      path.resolve(__dirname, 'src/frontend/js/lib'),
      path.resolve(__dirname, 'node_modules'),
    ],
  },

  target: 'web',

  stats: 'normal',
}
