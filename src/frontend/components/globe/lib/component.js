import { Component } from 'component'
import * as Plotly from 'plotly/plotly-geo-2.26.0'
// Use following line once patches merged upstream
// import Plotly from 'plotly.js-geo-dist'

class GlobeComponent extends Component {
  constructor(element) {
    super(element)
    this.initGlobe()
  }

  initGlobe() {
    Plotly.setPlotConfig({ locale: "en-GB" })

    const globeBase = $(this.element).data("globe-data")
    const globe_data = JSON.parse(atob(globeBase))
    const data = globe_data.data

    const layout = {
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
    }

    const options = {
      showLink: false,
      displaylogo: false,
      modeBarButtonsToRemove: ["sendDataToCloud"],
      topojsonURL: $(this.element).data("topojsonurl")
    }

    Plotly.newPlot(this.element, data, layout, options).then(function (gd) {
      // Set up handler to show records of country when country is clicked
      gd.on("plotly_click", function (d) {
        // Prevent click event when map is dragged
        if (d.event.defaultPrevented) return;

        const pt = (d.points || [])[0]; // Point clicked

        const params = globe_data.params;

        // Construct filter to only show country clicked.
        // XXX This will filter only when all globe fields of the record
        // are equal to the country. This should be an "OR" condition
        // instead
        const filter = params.globe_fields
          .map(function (field) {
            return field + "=" + pt.location;
          })
          .join("&");

        let url =
          "/" +
          params.layout_identifier +
          "/data?viewtype=table&view=" +
          params.view_id +
          "&" +
          filter;
        if (params.default_view_limit_extra_id) {
          url = url + "&extra=" + params.default_view_limit_extra_id;
        }
        location.href = url;
      })
    })
  }
}

export default GlobeComponent
