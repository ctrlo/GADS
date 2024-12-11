const path = require('path')
const { ProvidePlugin } = require('webpack')
const autoprefixer = require('autoprefixer')
const TerserPlugin = require('terser-webpack-plugin')
const { CleanWebpackPlugin } = require('clean-webpack-plugin')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const CopyWebpackPlugin = require('copy-webpack-plugin')

const stdExclusions = [/node_modules/, /test.[tj]sx?$/, /definitions\.[tj]sx?$/]

const plugins = [
    new ProvidePlugin({
        $: 'jquery',
        jQuery: 'jquery',
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
                from: "*.json",
                context: path.resolve(__dirname, 'src', 'frontend', 'js', 'lib', 'plotly')
            }
        ]
    }),
];

module.exports = (env) => {
    return {
        mode: env.development ? 'development' : 'production',
        devtool: env.development ? 'source-map' : false,
        entry: {
            site: path.resolve(__dirname, 'src', 'frontend', 'js', 'site.js'),
            '../css/general': path.resolve(__dirname, 'src', 'frontend', 'css', 'stylesheets', 'general.scss'),
            '../css/external': path.resolve(__dirname, 'src', 'frontend', 'css', 'stylesheets', 'external.scss'),
        },
        module: {
            rules: [
                {
                    test: /\.js$/i,
                    exclude: stdExclusions,
                    use: ['babel-loader']
                },
                {
                    test: /\.tsx?$/,
                    exclude: stdExclusions,
                    use: ['babel-loader', 'ts-loader']
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
                                postcssOptions: {
                                    plugins: [
                                        autoprefixer()
                                    ]
                                }
                            }
                        },
                        {
                            loader: 'sass-loader',
                            options: {
                                implementation: 'sass',
                                sassOptions: {
                                    loadPaths: ['src/frontend/components']
                                }
                            }
                        }
                    ]
                },
                {
                    test: /\.(eot|svg|ttf|woff|woff2|png|jpg|gif)$/i,
                    type: 'asset',
                },

                // Add your rules for custom modules here
                // Learn more about loaders from https://webpack.js.org/loaders/
            ],
        },
        plugins,
        optimization: {
            minimize: !env.development,
            minimizer: [
                new TerserPlugin({
                    terserOptions: {
                        format: {
                            comments: env.development ? 'all' : false,
                        },
                    },
                    extractComments: false,
                })
            ],
        },
        output: {
            filename: '[name].js',
            path: path.resolve(__dirname, 'public', 'js'),
            chunkFilename: '[name].[chunkhash].js',
        },
        resolve: {
            alias: {
                components: path.resolve(__dirname, 'src', 'frontend', 'components'),
                jQuery: path.resolve(__dirname, 'node_modules', 'jquery', 'dist', 'jquery.js'),
            },
            extensions: ['.tsx', '.ts', '.jsx', '.js'],
            modules: [
                path.resolve(__dirname, 'src', 'frontend', 'js', 'lib'),
                path.resolve(__dirname, 'node_modules')
            ]
        },
    }
};
