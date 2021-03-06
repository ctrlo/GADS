// Functions for graph plotting
var do_plot = function(plotData, options_in) {
  var ticks = plotData.xlabels;
  var plotOptions = {};
  var showmarker = options_in.type == "line" ? true : false;
  plotOptions.highlighter = {
    showMarker: showmarker,
    tooltipContentEditor: function(str, pointIndex, index, plot) {
      return plot._plotData[pointIndex][index][1];
    }
  };
  if (options_in.type == "bar") {
    plotOptions.seriesDefaults = {
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
    };
  } else if (options_in.type == "donut") {
    plotOptions.seriesDefaults = {
      renderer: $.jqplot.DonutRenderer,
      rendererOptions: {
        sliceMargin: 3,
        showDataLabels: true,
        dataLabels: "value",
        shadow: false
      }
    };
  } else if (options_in.type == "pie") {
    plotOptions.seriesDefaults = {
      renderer: $.jqplot.PieRenderer,
      rendererOptions: {
        showDataLabels: true,
        dataLabels: "value",
        shadow: false
      }
    };
  } else {
    plotOptions.seriesDefaults = {
      pointLabels: {
        show: false
      }
    };
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
  $.jqplot("chartdiv" + options_in.id, plotData.points, plotOptions);
};

// At the moment, do_plot_json needs to be exported globally, as it is used by
// Phantomjs to produce PNG versions of the graphs. Once jqplot has been
// replaced by a more modern graphing library, the PNG/Phantomjs functionality
// will probably unneccessary if that functionality is built into the library.
var do_plot_json = (window.do_plot_json = function(plotData, options_in) {
  plotData = JSON.parse(base64.decode(plotData));
  options_in = JSON.parse(base64.decode(options_in));
  do_plot(plotData, options_in);
});

export { do_plot_json };
