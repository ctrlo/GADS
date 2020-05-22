const setupGlobeById = (() => {
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

  return context => {
    initGlobe(context);
  };
})()

const setupGlobeByClass = (() => {
  var initGlobe = function (container) {
    Plotly.setPlotConfig({locale: 'en-GB'});

    var globe_data = JSON.parse(base64.decode(container.data('globe-data')));
    var data = globe_data.data;

    var layout = {
        margin: {
            t: 10,
            l: 10,
            r: 10,
            b: 10
        },
        geo: {
            scope: 'world',
            showcountries: true,
            countrycolor: 'grey',
            resolution: 110
        }
    };

    var options = {
        showLink: false,
        displaylogo: false,
        'modeBarButtonsToRemove' : ['sendDataToCloud'],
        topojsonURL: container.data('topojsonurl')
    };

    Plotly.newPlot(container.get(0), data, layout, options).then(function(gd) {
        // Set up handler to show records of country when country is clicked
        gd.on('plotly_click', function(d) {
            // Prevent click event when map is dragged
            if (d.event.defaultPrevented) return;

            var pt = (d.points || [])[0]; // Point clicked

            var params = globe_data.params;

            // Construct filter to only show country clicked.
            // XXX This will filter only when all globe fields of the record
            // are equal to the country. This should be an "OR" condition
            // instead
            var filter = params.globe_fields.map(function(field) {
                return field + "=" + pt.location
            }).join('&');

            var url = "/" + params.layout_identifier + "/data?viewtype=table&view=" + params.view_id + "&" + filter;
            if (params.default_view_limit_extra_id) {
                url = url + "&extra=" + params.default_view_limit_extra_id;
            }
            location.href = url;
        })
    });
  };

  return context => {
    initGlobe(context);
  };
})()


export { setupGlobeById, setupGlobeByClass };
