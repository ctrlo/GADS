module.exports = {
  "presets": [
    "@babel/preset-env",
    "@babel/preset-typescript",
    "@babel/preset-react"
  ],
  // ignore the plotly files as babel will mash them and they will not work
  "ignore": [
    "src/frontend/js/lib/plotly/*.js",
  ]
}
