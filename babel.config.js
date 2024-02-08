module.exports = {
  "presets": [
    [
      "@babel/preset-env",
      {
        "useBuiltIns": "usage",
        "corejs": "3.8",
        "targets": {
          "edge": "17",
          "firefox": "60",
          "chrome": "67",
          "safari": "11.1",
          "ie": "11"
        }
      }
    ],
    "@babel/preset-typescript",
    "@babel/preset-react"
  ],
  // ignore the plotly files as babel will mash them and they will not work
  "ignore": [
    "src/frontend/js/lib/plotly/*.js",
  ]
}
