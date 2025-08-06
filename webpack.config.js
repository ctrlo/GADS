const path = require('path')
const { ProvidePlugin, WatchIgnorePlugin } = require('webpack')
const autoprefixer = require('autoprefixer')
const sass = require('sass')
const TerserPlugin = require('terser-webpack-plugin')
const { CleanWebpackPlugin } = require('clean-webpack-plugin')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const CopyWebpackPlugin = require('copy-webpack-plugin')
const { execSync } = require('child_process')
const { existsSync } = require('fs');

const plugins = [
  {
    apply: (compiler) => {
      compiler.hooks.done.tap('RestorePlugin', () => {
        console.log('\nChecking for fengari-web.js restoration...\n');
        if(!existsSync(path.resolve(__dirname, 'public', 'js', 'fengari-web.js'))) {
          console.log('Restoring fengari-web.js from git...');
          execSync('git restore public/js/fengari-web.js', { stdio: 'inherit' });
        }
      });
    }
  },
  new ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    Buffer: ['buffer', 'Buffer'],
    // Required for more effective component integration
    "window.jQuery": 'jquery',
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
  // When watching, this plugin ensures that only the relevant folders are watched, increasing efficiency of the build
  new WatchIgnorePlugin({
    paths: [
      path.resolve(__dirname, 'node_modules'),
      path.resolve(__dirname, 'public'),
      path.resolve(__dirname, 'cypress'),
      path.resolve(__dirname, 'webpack'),
    ],
  })
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
          exclude: [/node_modules/, /\.test\.js$/, /test/, /definitions/],
          use: ['babel-loader']
        },
        {
          test: /\.tsx?$/,
          exclude: [/node_modules/, /\.test\.tsx?$/, /test/, /definitions/],
          use: ['babel-loader', 'ts-loader']
        },
        {
          test: /\.(gif|jpg|png|svg|eot|ttf|woff|woff2)$/,
          type: 'asset',
        },
        {
          test: /\.(scss|css)$/,
          exclude: [/node_modules/],
          use: [
            {
              loader: MiniCssExtractPlugin.loader,
            },
            {
              loader: 'css-loader',
              options: {
                importLoaders: 2,
                // Include source map for SCSS files for debugging if the environment is set to debug
                sourceMap: env.development,
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
            // As the terser can sometimes shorten class names to contain invalid characters and as the component class uses
            // the class name within a data attribute to ascertain initialization (`component.js:12), this can cause errors
            keep_classnames: true,
            // Include source map for SCSS files for debugging if the environment is set to debug
            sourceMap: env.development
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
