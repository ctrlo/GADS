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
    this.do_plot(plotData, options_in)
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
      success: function(data) {
        ret = data
      }
    })
    return ret
  }

  /**
   * Plot the graph data
   * @param {*} plotData The data for the graph
   * @param {*} options_in The options for the graph
   */
  do_plot(plotData, options_in) {
    const ticks = plotData.xlabels
    let plotOptions = {}
    const showmarker = options_in.type == 'line' ? true : false

    plotOptions.highlighter = {
      showMarker: showmarker,
      tooltipContentEditor: (str, pointIndex, index, plot) =>
        plot._plotData[pointIndex][index][1]
    };

    const seriesDefaults = this.makeSeriesDefaults()
    if (options_in.type in seriesDefaults) {
      plotOptions.seriesDefaults = seriesDefaults[options_in.type]
    } else {
      plotOptions.seriesDefaults = seriesDefaults.default
    }

    if (options_in.type != 'donut' && options_in.type != 'pie') {
      plotOptions.series = plotData.labels
      plotOptions.axes = {
        xaxis: {
          renderer: $.jqplot.CategoryAxisRenderer,
          ticks: ticks,
          label: options_in.x_axis_name,
          labelRenderer: $.jqplot.CanvasAxisLabelRenderer
        },
        yaxis: {
          label: options_in.y_axis_label,
          labelRenderer: $.jqplot.CanvasAxisLabelRenderer
        }
      }

      if (plotData.options.y_max) {
        plotOptions.axes.yaxis.max = plotData.options.y_max;
      }

      if (plotData.options.is_metric) {
        plotOptions.axes.yaxis.tickOptions = {
          formatString: '%d%'
        }
      }

      plotOptions.axesDefaults = {
        tickRenderer: $.jqplot.CanvasAxisTickRenderer,
        tickOptions: {
          angle: -30,
          fontSize: '8pt'
        }
      }
    }
    plotOptions.stackSeries = options_in.stackseries
    plotOptions.legend = {
      renderer: $.jqplot.EnhancedLegendRenderer,
      show: options_in.showlegend,
      location: 'ne',
      placement: 'inside'
    }
    plotOptions.grid = {
      background: '#ffffff',
      shadow: false
    }
    $(`[data-chart-id=${options_in.id}]`).jqplot(plotData.points, plotOptions)
  }

  /**
   * Make the series defaults for a graph
   * @returns {object} Default values for the graph
   */
  makeSeriesDefaults = () => ({
    bar: {
      renderer: $.jqplot.BarRenderer,
      rendererOptions: {
        shadow: false,
        fillToZero: true,
        barMinWidth: 10
      },
      pointLabels: {
        show: false,
        hideZeros: true
      }
    },
    donut: {
      renderer: $.jqplot.DonutRenderer,
      rendererOptions: {
        sliceMargin: 3,
        showDataLabels: true,
        dataLabels: "value",
        shadow: false
      }
    },
    pie: {
      renderer: $.jqplot.PieRenderer,
      rendererOptions: {
        showDataLabels: true,
        startAngle: -90,
        dataLabels: "value",
        shadow: false
      }
    },
    default: {
      pointLabels: {
        show: false
      }
    }
  })
}

export default GraphComponent
