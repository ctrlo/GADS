const do_plot = (plotData, options_in) => {
    const ticks = plotData.xlabels;
    let plotOptions = {};
    const showmarker = options_in.type == 'line' ? true : false;

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

    if (options_in.type != 'donut' && options_in.type != 'pie') {
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
                formatString: '%d%'
            };
        }

        plotOptions.axesDefaults = {
            tickRenderer: $.jqplot.CanvasAxisTickRenderer,
            tickOptions: {
                angle: -30,
                fontSize: '8pt'
            }
        };
    }
    plotOptions.stackSeries = options_in.stackseries;
    plotOptions.legend = {
        renderer: $.jqplot.EnhancedLegendRenderer,
        show: options_in.showlegend,
        location: 'ne',
        placement: 'inside'
    };
    plotOptions.grid = {
        background: '#ffffff',
        shadow: false
    };
    $(`[data-chart-id=${options_in.id}]`).jqplot(plotData.points, plotOptions);
};

// At the moment, do_plot_json needs to be exported globally, as it is used by
// Phantomjs to produce PNG versions of the graphs. Once jqplot has been
// replaced by a more modern graphing library, the PNG/Phantomjs functionality
// will probably unneccessary if that functionality is built into the library.
const do_plot_json = (window.do_plot_json = function(plotData, options_in) {
    plotData = JSON.parse(atob(plotData));
    options_in = JSON.parse(atob(options_in));
    do_plot(plotData, options_in);
});

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
            dataLabels: 'value',
            shadow: false
        }
    },
    pie: {
        renderer: $.jqplot.PieRenderer,
        rendererOptions: {
            showDataLabels: true,
            startAngle: -90,
            dataLabels: 'value',
            shadow: false
        }
    },
    default: {
        pointLabels: {
            show: false
        }
    }
});

export { do_plot_json };
