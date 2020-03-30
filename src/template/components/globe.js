const initGlobe = context => {
  const globeEl = $("#globe", context);
  if (!globeEl.length) return;

  Plotly.setPlotConfig({ locale: "en-GB" });

  var data = JSON.parse(base64.decode(globeEl.attr("data-globe")));

  var layout = {
    margin: {
      t: 10,
      l: 10,
      r: 10,
      b: 10
    },
    geo: {
      scope: "world",
      showcountries: true,
      countrycolor: "grey",
      resolution: 110
    }
  };

  var options = {
    showLink: false,
    displaylogo: false,
    modeBarButtonsToRemove: ["sendDataToCloud"],
    topojsonURL: `${globeEl.attr("data-url")}/`
  };

  Plotly.newPlot("globe", data, layout, options);
};

const setup = context => {
  initGlobe(context);
};

export default setup;
