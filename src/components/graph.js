import { setupFontAwesome } from "./font-awesome";

const setupGraph = (() => {
  const makeSeriesDefaults = () => ({
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
        dataLabels: "value",
        shadow: false
      }
    },
    default: {
      pointLabels: {
        show: false
      }
    }
  });

  const do_plot = (plotData, options_in) => {
    var ticks = plotData.xlabels;
    var plotOptions = {};
    var showmarker = options_in.type == "line" ? true : false;
    plotOptions.highlighter = {
      showMarker: showmarker,
      tooltipContentEditor: (str, pointIndex, index, plot) =>
        plot._plotData[pointIndex][index][1]
    };
    const seriesDefaults = makeSeriesDefaults();
    if (options_in.type in seriesDefaults) {
      plotOptions.seriesDefaults = seriesDefaults[options_in.type];
    } else {
      plotOptions.seriesDefaults = seriesDefaults.default;
    }
    if (options_in.type != "donut" && options_in.type != "pie") {
      plotOptions.series = plotData.labels;
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
      };
      if (plotData.options.y_max) {
        plotOptions.axes.yaxis.max = plotData.options.y_max;
      }
      if (plotData.options.is_metric) {
        plotOptions.axes.yaxis.tickOptions = {
          formatString: "%d%"
        };
      }
      plotOptions.axesDefaults = {
        tickRenderer: $.jqplot.CanvasAxisTickRenderer,
        tickOptions: {
          angle: -30,
          fontSize: "8pt"
        }
      };
    }
    plotOptions.stackSeries = options_in.stackseries;
    plotOptions.legend = {
      renderer: $.jqplot.EnhancedLegendRenderer,
      show: options_in.showlegend,
      location: "e",
      placement: "outside"
    };
    $.jqplot(`chartdiv${options_in.id}`, plotData.points, plotOptions);
  };

  const ajaxDataRenderer = url => {
    var ret = null;
    $.ajax({
      async: false,
      url: url,
      dataType: "json",
      success: function(data) {
        ret = data;
      }
    });
    return ret;
  };

  const setupCharts = chartDivs => {
    setupFontAwesome();

    $.jqplot.config.enablePlugins = true;

    chartDivs.each((i, val) => {
      const data = $(val).data();
      var time = new Date().getTime();
      var jsonurl = `/${data.layoutId}/data_graph/${data.graphId}/${time}`;
      var plotData = ajaxDataRenderer(jsonurl);
      var options_in = {
        type: data.graphType,
        x_axis_name: data.xAxisName,
        y_axis_label: data.yAxisLabel,
        stackseries: data.stackseries,
        showlegend: data.showlegend,
        id: data.graphId
      };
      do_plot(plotData, options_in);
    });
  };

  const initGraph = context => {
    const chartDiv = $("#chartdiv", context);
    const chartDivs = $("[id^=chartdiv]", context);
    if (!chartDiv.length && chartDivs.length) setupCharts(chartDivs);
  };

  return context => {
    // jqplot does not work in IE8 unless in document.ready
    $(document).ready(function() {
      initGraph(context);
    });
  };
})();

export { setupGraph };
