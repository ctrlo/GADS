import { Component } from 'component'
import '../../../js/lib/jqplot/jquery.jqplot.min'
import '../../../js/lib/jqplot/jqplot.barRenderer'
import '../../../js/lib/jqplot/jqplot.pieRenderer'
import '../../../js/lib/jqplot/jqplot.donutRenderer'
import '../../../js/lib/jqplot/jqplot.canvasTextRenderer'
import '../../../js/lib/jqplot/jqplot.categoryAxisRenderer'
import '../../../js/lib/jqplot/jqplot.canvasAxisLabelRenderer'
import '../../../js/lib/jqplot/jqplot.canvasAxisTickRenderer'
import '../../../js/lib/jqplot/jqplot.highlighter'
import { do_plot } from "components/graph/lib/chart";

/**
 * Graph component using JQPlot
 */
class GraphComponent extends Component {
  /**
   * Create a new graph component
   * @param {HTMLElement} element The element to attach the component to
   */
  constructor(element) {
    super(element)
    this.graphContainer = $(this.element).find('.graph__container')

    if (this.graphContainer.length) {
      this.initGraph()
    }
  }

  /**
   * Initialize the graph
   */
  initGraph() {
    $.jqplot.config.enablePlugins = true
    const data = this.graphContainer.data()
    const jsonurl = this.getURL(data)
    const plotData = this.ajaxDataRenderer(jsonurl)
    const options_in = {
      type: data.graphType,
      x_axis_name: data.xAxisName,
      y_axis_label: data.yAxisLabel,
      stackseries: data.stackseries,
      showlegend: data.showlegend,
      id: data.graphId
    }
    do_plot(plotData, options_in)
  }

  /**
   * Get the URL for the graph data
   * @param {*} data The data for the graph
   */
  getURL(data) {
    let devEndpoint

    if (['bar', 'line', 'scatter'].indexOf(data.graphType) > -1) {
      devEndpoint = window.siteConfig && window.siteConfig.urls.barApi
    } else if (['donut', 'pie'].indexOf(data.graphType) > -1) {
      devEndpoint = window.siteConfig && window.siteConfig.urls.pieApi
    }

    if (devEndpoint) {
      return devEndpoint
    } else {
      const time = new Date().getTime()
      return `/${data.layoutId}/data_graph/${data.graphId}/${time}`
    }
  }

  /**
   * Data renderer that fetches the data for the graph
   * @param {*} url The URL to fetch data from
   * @returns A data object for the graph
   */
  ajaxDataRenderer(url) {
    let ret = null

    $.ajax({
      async: false,
      url: url,
      dataType: 'json',
      success: function (data) {
        ret = data
      }
    })
    return ret
  }
}

export default GraphComponent
