"use strict";

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); if (enumerableOnly) symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; }); keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; if (i % 2) { ownKeys(Object(source), true).forEach(function (key) { _defineProperty(target, key, source[key]); }); } else if (Object.getOwnPropertyDescriptors) { Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)); } else { ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

//
// setupFontAwesome
//
var setupFontAwesome = function setupFontAwesome() {
  if (!window.FontDetect) return;

  if (!FontDetect.isFontLoaded("14px/1 FontAwesome")) {
    $(".use-icon-font").hide();
    $(".use-icon-png").show();
  }
}; //
// setupBuilder
//


var setupBuilder = function () {
  var buildFilterOperators = function buildFilterOperators(type) {
    if (!["date", "daterange"].includes(type)) return undefined;
    var operators = ["equal", "not_equal", "less", "less_or_equal", "greater", "greater_or_equal", "is_empty", "is_not_empty"];
    type === "daterange" && operators.push("contain");
    return operators;
  };

  var typeaheadProperties = function typeaheadProperties(urlSuffix, layoutId, instanceId) {
    return {
      input: function input(container, rule, input_name) {
        return "<input class=\"typeahead_text\" type=\"text\" name=\"".concat(input_name, "_text\">\n      <input class=\"typeahead_hidden\" type=\"hidden\" name=\"").concat(input_name, "\"></input>");
      },
      valueSetter: function valueSetter($rule, value, filter, operator, data) {
        $rule.find(".typeahead_text").val(data.text);
        $rule.find(".typeahead_hidden").val(value);
      },
      onAfterCreateRuleInput: function onAfterCreateRuleInput($rule) {
        var $ruleInputText = $("#".concat($rule.attr("id"), " .rule-value-container input[type=\"text\"]"));
        var $ruleInputHidden = $("#".concat($rule.attr("id"), " .rule-value-container input[type=\"hidden\"]"));
        $ruleInputText.attr("autocomplete", "off");
        $ruleInputText.typeahead({
          delay: 100,
          matcher: function matcher() {
            return true;
          },
          sorter: function sorter(items) {
            return items;
          },
          afterSelect: function afterSelect(selected) {
            if (_typeof(selected) === "object") {
              $ruleInputHidden.val(selected.id);
            } else {
              $ruleInputHidden.val(selected);
            }
          },
          source: function source(query, process) {
            return $.ajax({
              type: "GET",
              url: "/".concat(layoutId, "/match/layout/").concat(urlSuffix),
              data: {
                q: query,
                oi: instanceId
              },
              success: function success(result) {
                process(result);
              },
              dataType: "json"
            });
          }
        });
      }
    };
  };

  var ragProperties = {
    input: "select",
    values: {
      b_red: "Red",
      c_amber: "Amber",
      c_yellow: "Yellow",
      d_green: "Green",
      a_grey: "Grey",
      e_purple: "Purple"
    }
  };

  var buildFilter = function buildFilter(builderConfig, col) {
    return _objectSpread({
      id: col.filterId,
      label: col.label,
      type: "string",
      operators: buildFilterOperators(col.type)
    }, col.type === "rag" ? ragProperties : col.hasFilterTypeahead ? typeaheadProperties(col.urlSuffix, builderConfig.layoutId, col.instanceId) : {});
  };

  var makeUpdateFilter = function makeUpdateFilter() {
    window.UpdateFilter = function (builder) {
      var res = builder.queryBuilder("getRules");
      $("#filter").val(JSON.stringify(res, null, 2));
    };
  };

  var operators = [{
    type: "equal",
    accept_values: true,
    apply_to: ["string", "number", "datetime"]
  }, {
    type: "not_equal",
    accept_values: true,
    apply_to: ["string", "number", "datetime"]
  }, {
    type: "less",
    accept_values: true,
    apply_to: ["string", "number", "datetime"]
  }, {
    type: "less_or_equal",
    accept_values: true,
    apply_to: ["string", "number", "datetime"]
  }, {
    type: "greater",
    accept_values: true,
    apply_to: ["string", "number", "datetime"]
  }, {
    type: "greater_or_equal",
    accept_values: true,
    apply_to: ["string", "number", "datetime"]
  }, {
    type: "contains",
    accept_values: true,
    apply_to: ["datetime", "string"]
  }, {
    type: "not_contains",
    accept_values: true,
    apply_to: ["datetime", "string"]
  }, {
    type: "begins_with",
    accept_values: true,
    apply_to: ["string"]
  }, {
    type: "not_begins_with",
    accept_values: true,
    apply_to: ["string"]
  }, {
    type: "is_empty",
    accept_values: false,
    apply_to: ["string", "number", "datetime"]
  }, {
    type: "is_not_empty",
    accept_values: false,
    apply_to: ["string", "number", "datetime"]
  }, {
    type: "changed_after",
    nb_inputs: 1,
    accept_values: true,
    multiple: false,
    apply_to: ["string", "number", "datetime"]
  }];

  var setupBuilder = function setupBuilder(builderEl) {
    var builderConfig = JSON.parse($(builderEl).html());
    if (builderConfig.filterNotDone) makeUpdateFilter();
    $("#builder".concat(builderConfig.builderId)).queryBuilder({
      showPreviousValues: builderConfig.showPreviousValues,
      filters: builderConfig.filters.map(function (col) {
        return buildFilter(builderConfig, col);
      }),
      operators: operators,
      lang: {
        operators: {
          changed_after: "changed on or after"
        }
      }
    });
  };

  var setupAllBuilders = function setupAllBuilders(context) {
    $('script[id^="builder_json_"]', context).each(function (i, builderEl) {
      setupBuilder(builderEl);
    });
  };

  var setupTypeahead = function setupTypeahead(context) {
    $(document, context).on("input", ".typeahead_text", function () {
      var value = $(this).val();
      $(this).next(".typeahead_hidden").val(value);
    });
  };

  return function (context) {
    setupAllBuilders(context);
    setupTypeahead(context);
  };
}(); //
// setupCalendar
//


var setupCalendar = function () {
  var initCalendar = function initCalendar(context) {
    var calendarEl = $("#calendar", context);
    if (!calendarEl.length) return false;
    var options = {
      events_source: "/".concat(calendarEl.attr("data-event-source"), "/data_calendar/").concat(new Date().getTime()),
      view: calendarEl.data("view"),
      tmpl_path: "/tmpls/",
      tmpl_cache: false,
      onAfterEventsLoad: function onAfterEventsLoad(events) {
        if (!events) {
          return;
        }

        var list = $("#eventlist");
        list.html("");
        $.each(events, function (key, val) {
          $(document.createElement("li")).html("<a href=\"".concat(val.url, "\">").concat(val.title, "</a>")).appendTo(list);
        });
      },
      onAfterViewLoad: function onAfterViewLoad(view) {
        $("#caltitle").text(this.getTitle());
        $(".btn-group button").removeClass("active");
        $("button[data-calendar-view=\"".concat(view, "\"]")).addClass("active");
      },
      classes: {
        months: {
          general: "label"
        }
      }
    };
    var day = calendarEl.data("calendar-day-ymd");

    if (day) {
      options.day = day;
    }

    return calendarEl.calendar(options);
  };

  var setupButtons = function setupButtons(calendar, context) {
    $(".btn-group button[data-calendar-nav]", context).each(function () {
      var $this = $(this);
      $this.click(function () {
        calendar.navigate($this.data("calendar-nav"));
      });
    });
    $(".btn-group button[data-calendar-view]", context).each(function () {
      var $this = $(this);
      $this.click(function () {
        calendar.view($this.data("calendar-view"));
      });
    });
  };

  var setupSpecifics = function setupSpecifics(calendar, context) {
    $("#first_day", context).change(function () {
      var value = $(this).val();
      value = value.length ? parseInt(value) : null;
      calendar.setOptions({
        first_day: value
      });
      calendar.view();
    });
    $("#language", context).change(function () {
      calendar.setLanguage($(this).val());
      calendar.view();
    });
    $("#events-in-modal", context).change(function () {
      var val = $(this).is(":checked") ? $(this).val() : null;
      calendar.setOptions({
        modal: val
      });
    });
    $("#events-modal .modal-header, #events-modal .modal-footer", context).click(function () {});
  };

  return function (context) {
    var calendar = initCalendar(context);

    if (calendar) {
      setupButtons(calendar, context);
      setupSpecifics(calendar, context);
      setupFontAwesome();
    }
  };
}(); //
// setupCurvalModal
//


var setupCurvalModal = function () {
  var curvalModalValidationSucceeded = function curvalModalValidationSucceeded(form, values, context) {
    var form_data = form.serialize();
    var modal_field_ids = form.data("modal-field-ids");
    var col_id = form.data("curval-id");
    var instance_name = form.data("instance-name");
    var guid = form.data("guid");
    var hidden_input = $("<input>", context).attr({
      type: "hidden",
      name: "field" + col_id,
      value: form_data
    });
    var $formGroup = $("div[data-column-id=" + col_id + "]", context);
    var valueSelector = $formGroup.data("value-selector");

    if (valueSelector === "noshow") {
      var row_cells = $('<tr class="curval_item">', context);
      jQuery.map(modal_field_ids, function (element) {
        var control = form.find('[data-column-id="' + element + '"]');
        var value = getFieldValues(control);
        value = values["field" + element];
        value = $("<div />", context).text(value).html();
        row_cells.append($('<td class="curval-inner-text">', context).append(value));
      });
      var links = $("<td>\n        <a class=\"curval-modal\" style=\"cursor:pointer\" data-layout-id=\"".concat(col_id, " data-instance-name=").concat(instance_name, ">edit</a> | <a class=\"curval_remove\" style=\"cursor:pointer\">remove</a>\n      </td>"), context);
      row_cells.append(links.append(hidden_input));

      if (guid) {
        var hidden = $('input[data-guid="' + guid + '"]', context).val(form_data);
        hidden.closest(".curval_item").replaceWith(row_cells);
      } else {
        $("#curval_list_".concat(col_id), context).find("tbody").prepend(row_cells);
      }
    } else if (valueSelector === "dropdown") {
      var $widget = $formGroup.find(".select-widget").first();
      var multi = $widget.hasClass("multi");
      var $currentItems = $formGroup.find(".current [data-list-item]");
      var $search = $formGroup.find(".current .search");
      var $answersList = $formGroup.find(".available");

      if (!multi) {
        /* Deselect current selected value */
        $currentItems.attr("hidden", "");
        $answersList.find("li input").prop("checked", false);
      }

      var textValue = jQuery.map(modal_field_ids, function (element) {
        var value = values["field" + element];
        return $("<div />").text(value).html();
      }).join(", ");
      guid = window.guid();
      var id = "field".concat(col_id, "_").concat(guid);
      var deleteButton = multi ? '<button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete" title="delete" tabindex="-1">&times;</button>' : "";
      $search.before("<li data-list-item=\"".concat(id, "\">").concat(textValue).concat(deleteButton, "</li>"));
      var inputType = multi ? "checkbox" : "radio";
      $answersList.append("<li class=\"answer\">\n        <span class=\"control\">\n            <label id=\"".concat(id, "_label\" for=\"").concat(id, "\">\n                <input id=\"").concat(id, "\" name=\"field").concat(col_id, "\" type=\"").concat(inputType, "\" value=\"").concat(form_data, "\" class=\"").concat(multi ? "" : "visually-hidden", "\" checked aria-labelledby=\"").concat(id, "_label\">\n                <span>").concat(textValue, "</span>\n            </label>\n        </span>\n        <span class=\"details\">\n            <a class=\"curval_remove\" style=\"cursor:pointer\">remove</a>\n        </span>\n      </li>"));
      /* Reinitialize widget */

      setupSelectWidgets($formGroup);
    } else if (valueSelector === "typeahead") {
      var $hiddenInput = $formGroup.find("input[name=field".concat(col_id, "]"));
      var $typeaheadInput = $formGroup.find("input[name=field".concat(col_id, "_typeahead]"));
      var textValueHead = jQuery.map(modal_field_ids, function (element) {
        var value = values["field" + element];
        return $("<div />").text(value).html();
      }).join(", ");
      $hiddenInput.val(form_data);
      $typeaheadInput.val(textValueHead);
    }

    $(".modal.in", context).modal("hide");
  };

  var curvalModalValidationFailed = function curvalModalValidationFailed(form, errorMessage) {
    form.find(".alert").text(errorMessage).removeAttr("hidden");
    form.parents(".modal-content").get(0).scrollIntoView();
    form.find("button[type=submit]").prop("disabled", false);
  };

  var setupAddButton = function setupAddButton(context) {
    $(document, context).on("mousedown", ".curval-modal", function (e) {
      var layout_id = $(e.target).data("layout-id");
      var instance_name = $(e.target).data("instance-name");
      var current_id = $(e.target).data("current-id");
      var hidden = $(e.target).closest(".curval_item").find("input[name=field".concat(layout_id, "]"));
      var form_data = hidden.val();
      var mode = hidden.length ? "edit" : "add";
      var guid;

      if (mode === "edit") {
        guid = hidden.data("guid");

        if (!guid) {
          guid = window.guid();
          hidden.attr("data-guid", guid);
        }
      }

      var m = $("#curval_modal", context);
      m.find(".modal-body").text("Loading...");
      var url = current_id ? "/record/".concat(current_id) : "/".concat(instance_name, "/record/");
      m.find(".modal-body").load("".concat(url, "?include_draft&modal=").concat(layout_id, "&").concat(form_data), function () {
        if (mode === "edit") {
          m.find("form").data("guid", guid);
        }

        Linkspace.init(m);
      });
      m.on("focus", ".datepicker", function () {
        $(this).datepicker({
          format: m.attr("data-dateformat-datepicker"),
          autoclose: true
        });
      });
      m.modal();
    });
  };

  var setupSubmit = function setupSubmit(context) {
    $("#curval_modal", context).on("submit", ".curval-edit-form", function (e) {
      e.preventDefault();
      var form = $(this);
      var form_data = form.serialize();
      form.addClass("edit-form--validating");
      form.find(".alert").attr("hidden", "");
      $.post(form.attr("action") + "?validate&include_draft", form_data, function (data) {
        if (data.error === 0) {
          curvalModalValidationSucceeded(form, data.values);
        } else {
          var errorMessage = data.error === 1 ? data.message : "Oops! Something went wrong.";
          curvalModalValidationFailed(form, errorMessage);
        }
      }, "json").fail(function (jqXHR, textstatus, errorthrown) {
        var errorMessage = "Oops! Something went wrong: ".concat(textstatus, ": ").concat(errorthrown);
        curvalModalValidationFailed(form, errorMessage);
      }).always(function () {
        form.removeClass("edit-form--validating");
      });
    });
  };

  var setupRemoveCurval = function setupRemoveCurval(context) {
    $(".curval_group", context).on("click", ".curval_remove", function () {
      $(this).closest(".curval_item").remove();
    });
    $(".select-widget", context).on("click", ".curval_remove", function () {
      var fieldId = $(this).closest(".answer").find("input").prop("id");
      $(this).closest(".select-widget").find(".current li[data-list-item=".concat(fieldId, "]")).remove();
      $(this).closest(".answer").remove();
    });
  };

  return function (context) {
    setupAddButton(context);
    setupSubmit(context);
    setupRemoveCurval(context);
  };
}(); //
// setupDatePicker
//


var setupDatePicker = function () {
  var setupDatePickers = function setupDatePickers(context) {
    $(".datepicker", context).datepicker({
      format: $(document.body).data("config-dataformat-datepicker"),
      autoclose: true
    });
  };

  var setupDateRange = function setupDateRange(context) {
    $(".input-daterange input.from", context).each(function () {
      $(this).on("changeDate", function () {
        var toDatepicker = $(this).parents(".input-daterange").find(".datepicker.to");

        if (!toDatepicker.val()) {
          toDatepicker.datepicker("update", $(this).datepicker("getDate"));
        }
      });
    });
  };

  var setupRemoveDatePicker = function setupRemoveDatePicker(context) {
    $(document, context).on("click", ".remove_datepicker", function () {
      var dp = ".datepicker" + $(this).data("field");
      $(dp).datepicker("destroy"); //eslint-disable-next-line no-alert

      alert("Date selector has been disabled for this field");
    });
  };

  return function (context) {
    setupDatePickers(context);
    setupDateRange(context);
    setupRemoveDatePicker(context);
  };
}(); //
// setupEdit
//


var setupEdit = function () {
  var setupCloneAndRemove = function setupCloneAndRemove(context) {
    $(document, context).on("click", ".cloneme", function () {
      var parent = $(this).parents(".input_holder");
      var cloned = parent.clone();
      cloned.removeAttr("id").insertAfter(parent);
      cloned.find(":text").val("");
      cloned.find(".datepicker").datepicker({
        format: parent.attr("data-dateformat-datepicker"),
        autoclose: true
      });
    });
    $(document, context).on("click", ".removeme", function () {
      var parent = $(this).parents(".input_holder");

      if (parent.siblings(".input_holder").length > 0) {
        parent.remove();
      }
    });
  };

  var setupHelpTextModal = function setupHelpTextModal(context) {
    $("#helptext_modal", context).on("show.bs.modal", function (e) {
      var loadurl = $(e.relatedTarget).data("load-url");
      $(this).find(".modal-body").load(loadurl);
    });
    $(document, context).on("click", ".more-info", function (e) {
      var record_id = $(e.target).data("record-id");
      var m = $("#readmore_modal", context);
      m.find(".modal-body").text("Loading...");
      m.find(".modal-body").load("/record_body/" + record_id);
      /* Trigger focus restoration on modal close */

      m.one("show.bs.modal", function (showEvent) {
        /* Only register focus restorer if modal will actually get shown */
        if (showEvent.isDefaultPrevented()) {
          return;
        }

        m.one("hidden.bs.modal", function () {
          $(e.target, context).is(":visible") && $(e.target, context).trigger("focus");
        });
      });
      /* Stop propagation of the escape key, as may have side effects, like closing select widgets. */

      m.one("keyup", function (e) {
        if (e.keyCode == 27) {
          e.stopPropagation();
        }
      });
      m.modal();
    });
  };

  var setupTypeahead = function setupTypeahead(context) {
    $('input[type="text"][id^="typeahead_"]', context).each(function (i, typeaheadEl) {
      $(typeaheadEl, context).change(function () {
        if (!$(this).val()) {
          $("#".concat(typeaheadEl.id, "_value"), context).val("");
        }
      });
      $(typeaheadEl, context).typeahead({
        delay: 500,
        matcher: function matcher() {
          return true;
        },
        sorter: function sorter(items) {
          return items;
        },
        afterSelect: function afterSelect(selected) {
          $("#".concat(typeaheadEl.id, "_value"), context).val(selected.id);
        },
        source: function source(query, process) {
          return $.ajax({
            type: "GET",
            url: "/".concat($(typeaheadEl, context).data("layout-id"), "/match/layout/").concat($(typeaheadEl).data("typeahead-id")),
            data: {
              q: query
            },
            success: function success(result) {
              process(result);
            },
            dataType: "json"
          });
        }
      });
    });
  };

  return function (context) {
    setupCloneAndRemove(context);
    setupHelpTextModal(context);
    setupCurvalModal(context);
    setupDatePicker(context);
    setupTypeahead(context);
  };
}(); //
// setupGlobe
//


var setupGlobe = function () {
  var initGlobe = function initGlobe(context) {
    var globeEl = $("#globe", context);
    if (!globeEl.length) return;
    Plotly.setPlotConfig({
      locale: "en-GB"
    });
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
      topojsonURL: "".concat(globeEl.attr("data-url"), "/")
    };
    Plotly.newPlot("globe", data, layout, options);
  };

  return function (context) {
    initGlobe(context);
  };
}(); // setupGraph


var setupGraph = function () {
  var makeSeriesDefaults = function makeSeriesDefaults() {
    return {
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
      "default": {
        pointLabels: {
          show: false
        }
      }
    };
  };

  var do_plot = function do_plot(plotData, options_in) {
    var ticks = plotData.xlabels;
    var plotOptions = {};
    var showmarker = options_in.type == "line" ? true : false;
    plotOptions.highlighter = {
      showMarker: showmarker,
      tooltipContentEditor: function tooltipContentEditor(str, pointIndex, index, plot) {
        return plot._plotData[pointIndex][index][1];
      }
    };
    var seriesDefaults = makeSeriesDefaults();

    if (options_in.type in seriesDefaults) {
      plotOptions.seriesDefaults = seriesDefaults[options_in.type];
    } else {
      plotOptions.seriesDefaults = seriesDefaults["default"];
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
    $.jqplot("chartdiv".concat(options_in.id), plotData.points, plotOptions);
  };

  var ajaxDataRenderer = function ajaxDataRenderer(url) {
    var ret = null;
    $.ajax({
      async: false,
      url: url,
      dataType: "json",
      success: function success(data) {
        ret = data;
      }
    });
    return ret;
  };

  var setupCharts = function setupCharts(chartDivs) {
    setupFontAwesome();
    $.jqplot.config.enablePlugins = true;
    chartDivs.each(function (i, val) {
      var data = $(val).data();
      var time = new Date().getTime();
      var jsonurl = "/".concat(data.layoutId, "/data_graph/").concat(data.graphId, "/").concat(time);
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

  var initGraph = function initGraph(context) {
    var chartDiv = $("#chartdiv", context);
    var chartDivs = $("[id^=chartdiv]", context);
    if (!chartDiv.length && chartDivs.length) setupCharts(chartDivs);
  };

  return function (context) {
    initGraph(context);
  };
}(); //
// setupLayout
//


var setupLayout = function () {
  var setupDemoButtons = function setupDemoButtons(context) {
    var demo_delete = function demo_delete() {
      var ref = $("#jstree_demo_div", context).jstree(true),
          sel = ref.get_selected();

      if (!sel.length) {
        return false;
      }

      ref.delete_node(sel);
    };

    $("#btnDeleteNode", context).click(demo_delete);

    var demo_create = function demo_create() {
      var ref = $("#jstree_demo_div", context).jstree(true),
          sel = ref.get_selected();

      if (sel.length) {
        sel = sel[0];
      } else {
        sel = "#";
      }

      sel = ref.create_node(sel, {
        type: "file"
      });

      if (sel) {
        ref.edit(sel);
      }
    };

    $("#btnAddNode", context).click(demo_create);

    var demo_rename = function demo_rename() {
      var ref = $("#jstree_demo_div", context).jstree(true),
          sel = ref.get_selected();

      if (!sel.length) {
        return false;
      }

      sel = sel[0];
      ref.edit(sel);
    };

    $("#btnRenameNode", context).click(demo_rename);
  }; // No longer used? Where is #selectall ?


  var setupSelectAll = function setupSelectAll(context) {
    $("#selectall", context).click(function () {
      if ($(".check_perm:checked", context).length == 7) {
        $(".check_perm", context).prop("checked", false);
      } else {
        $(".check_perm", context).prop("checked", true);
      }
    });
  };

  var setupSortableHandle = function setupSortableHandle(context) {
    if (!$(".sortable", context).length) return;
    $(".sortable", context).sortable({
      handle: ".drag"
    });
  };

  var setupTreeDemo = function setupTreeDemo(context) {
    var treeEl = $("#jstree_demo_div", context);
    if (!treeEl.length) return;
    treeEl.jstree({
      core: {
        check_callback: true,
        force_text: true,
        themes: {
          stripes: true
        },
        data: {
          url: function url() {
            return "/".concat(treeEl.data("layout-identifier"), "/tree").concat(new Date().getTime(), "/").concat(treeEl.data("column-id"), "?");
          },
          data: function data(node) {
            return {
              id: node.id
            };
          }
        }
      }
    });
  };

  var setupDropdownValues = function setupDropdownValues(context) {
    $("div#legs", context).on("click", ".add", function (event) {
      $(event.currentTarget, context).closest("#legs").find(".sortable").append("\n          <div class=\"request-row\">\n            <p>\n              <input type=\"hidden\" name=\"enumval_id\">\n              <input type=\"text\" class=\"form-control\" style=\"width:80%; display:inline\" name=\"enumval\">\n              <button type=\"button\" class=\"close closeme\" style=\"float:none\">&times;</button>\n              <span class=\"fa fa-hand-paper-o fa-lg use-icon-font close drag\" style=\"float:none\"></span>\n            </p>\n          </div>\n      ");
      $(".sortable", context).sortable("refresh");
    });
    $("div#legs").on("click", ".closeme", function (event) {
      var count = $(".request-row", context).length;
      if (count < 2) return;
      $(event.currentTarget, context).parents(".request-row").remove();
    });
  };

  var setupTableDropdown = function setupTableDropdown(context) {
    $("#refers_to_instance_id", context).change(function (event) {
      var divid = "#instance_fields_".concat($(event.currentTarget, context).val());
      $(".instance_fields", context).hide();
      $(divid, context).show();
    });
  };

  var setupAutoValueField = function setupAutoValueField(context) {
    $("#related_field_id", context).change(function (event) {
      var divid = $(event.currentTarget).find(":selected").data("instance_id");
      $(".autocur_instance", context).hide();
      $("#autocur_instance_".concat(divid), context).show();
    });
    $("#filval_related_field_id", context).change(function () {
      var divid = $(this).val();
      $(".filval_curval", context).hide();
      $("#filval_curval_" + divid, context).show();
    });
  };

  var setupJsonFilters = function setupJsonFilters(context) {
    $('div[id^="builder"]', context).each(function (i, builderEl) {
      var filterBase = $(builderEl).data("filter-base");
      if (!filterBase) return;
      var data = base64.decode(filterBase);
      $(builderEl).queryBuilder("setRules", JSON.parse(data));
    });
  };

  var setupDisplayConditionsBuilder = function setupDisplayConditionsBuilder(context) {
    var conditionsBuilder = $("#displayConditionsBuilder", context);
    if (!conditionsBuilder.length) return;
    var builderData = conditionsBuilder.data();
    conditionsBuilder.queryBuilder({
      filters: builderData.filters,
      allow_groups: 0,
      operators: [{
        type: "equal",
        accept_values: true,
        apply_to: ["string"]
      }, {
        type: "contains",
        accept_values: true,
        apply_to: ["string"]
      }, {
        type: "not_equal",
        accept_values: true,
        apply_to: ["string"]
      }, {
        type: "not_contains",
        accept_values: true,
        apply_to: ["string"]
      }]
    });

    if (builderData.filterBase) {
      var data = base64.decode(builderData.filterBase);
      conditionsBuilder.queryBuilder("setRules", JSON.parse(data));
    }
  };

  var setupSubmitSave = function setupSubmitSave(context) {
    $("#submit_save", context).click(function () {
      var res = $("#displayConditionsBuilder", context).queryBuilder("getRules");
      $("#displayConditions", context).val(JSON.stringify(res, null, 2));
      var current_builder = "#builder".concat($("#refers_to_instance_id", context).val());
      var jstreeDemoDivEl = $("#jstree_demo_div", context);

      if (jstreeDemoDivEl.length && jstreeDemoDivEl.is(":visible")) {
        var v = jstreeDemoDivEl.jstree(true).get_json("#", {
          flat: false
        });
        var mytext = JSON.stringify(v);
        var data = jstreeDemoDivEl.data();
        $.ajax({
          async: false,
          type: "POST",
          url: "/".concat(data.layoutIdentifier, "/tree/").concat(data.columnId),
          data: {
            data: mytext,
            csrf_token: data.csrfToken
          }
        }).done(function () {
          // eslint-disable-next-line no-alert
          alert("Tree has been updated");
        });
        return true;
      } else if ($(current_builder, context).is(":visible")) {
        UpdateFilter($(current_builder, context));
      }

      return true;
    });
  };

  var setupType = function setupType(context) {
    $("#type", context).on("change", function () {
      var $mf = $("#manage-fields", context);
      var current_type = $mf.data("column-type");
      var new_type = $(this).val();
      $mf.removeClass("column-type-" + current_type);
      $mf.addClass("column-type-" + new_type);
      $mf.data("column-type", new_type);

      if (new_type == "rag" || new_type == "intgr" || new_type == "person") {
        $("#checkbox-multivalue", context).hide();
      } else {
        $("#checkbox-multivalue", context).show();
      }
    }).trigger("change");
  };

  return function (context) {
    setupDemoButtons(context);
    setupSelectAll(context);
    setupSortableHandle(context);
    setupTreeDemo(context);
    setupDropdownValues(context);
    setupTableDropdown(context);
    setupAutoValueField(context);
    setupJsonFilters(context);
    setupDisplayConditionsBuilder(context);
    setupSubmitSave(context);
    setupType(context);
  };
}(); //
// setupLogin
//


var setupLogin = function () {
  var setupOpenModalOnLoad = function setupOpenModalOnLoad(id, context) {
    var modalEl = $(id, context);

    if (modalEl.data("open-on-load")) {
      modalEl.modal("show");
    }
  };

  return function (context) {
    setupOpenModalOnLoad("#modalregister", context);
    setupOpenModalOnLoad("#modal-reset-password", context);
  };
}(); //
// setupMetric
//


var setupMetric = function () {
  var setupMetricModal = function setupMetricModal(context) {
    var modalEl = $("#modal_metric", context);
    if (!modalEl.length) return;
    modalEl.on("show.bs.modal", function (event) {
      var button = $(event.relatedTarget);
      var metric_id = button.data("metric_id");
      $("#metric_id", context).val(metric_id);

      if (metric_id) {
        $("#delete_metric", context).show();
      } else {
        $("#delete_metric", context).hide();
      }

      var target_value = button.data("target_value");
      $("#target_value", context).val(target_value);
      var x_axis_value = button.data("x_axis_value");
      $("#x_axis_value", context).val(x_axis_value);
      var y_axis_grouping_value = button.data("y_axis_grouping_value");
      $("#y_axis_grouping_value", context).val(y_axis_grouping_value);
    });
  };

  return function (context) {
    setupMetricModal(context);
  };
}(); //
// setupMyGraphs
//


var setupMyGraphs = function () {
  var setupDataTable = function setupDataTable(context) {
    var dtableEl = $("#mygraphs-table", context);
    if (!dtableEl.length) return;
    dtableEl.dataTable({
      columnDefs: [{
        targets: 0,
        orderable: false
      }],
      pageLength: 50,
      order: [[1, "asc"]]
    });
  };

  return function (context) {
    setupDataTable(context);
  };
}(); //
// setupPlaceholder
//


var setupPlaceholder = function () {
  var setupPlaceholder = function setupPlaceholder(context) {
    $("input, text", context).placeholder();
  };

  return function (context) {
    setupPlaceholder(context);
  };
}(); //
// setupPopover
//


var setupPopover = function () {
  var setupPopover = function setupPopover(context) {
    $('[data-toggle="popover"]', context).popover({
      placement: "auto",
      html: true
    });
  };

  return function (context) {
    setupPopover(context);
  };
}(); //
// setupPurge
//


var setupPurge = function () {
  var setupSelectAll = function setupSelectAll(context) {
    $("#selectall", context).click(function () {
      $(".record_selected", context).prop("checked", this.checked);
    });
  };

  return function (context) {
    setupSelectAll(context);
  };
}(); //
// setupTable
//


var setupTable = function () {
  var setupSendemailModal = function setupSendemailModal(context) {
    $("#modal_sendemail", context).on("show.bs.modal", function (event) {
      var button = $(event.relatedTarget);
      var peopcol_id = button.data("peopcol_id");
      $("#modal_sendemail_peopcol_id").val(peopcol_id);
    });
  };

  var setupHelptextModal = function setupHelptextModal(context) {
    $("#modal_helptext", context).on("show.bs.modal", function (event) {
      var button = $(event.relatedTarget);
      var col_name = button.data("col_name");
      $("#modal_helptext", context).find(".modal-title").text(col_name);
      var col_id = button.data("col_id");
      $.get("/helptext/" + col_id, function (data) {
        $("#modal_helptext", context).find(".modal-body").html(data);
      });
    });
  };

  var setupDataTable = function setupDataTable(context) {
    if (!$("#data-table", context).length) return;
    $("#data-table", context).floatThead({
      floatContainerCss: {},
      zIndex: function zIndex() {
        return 999;
      },
      ariaLabel: function ariaLabel($table, $headerCell) {
        return $headerCell.data("thlabel");
      }
    });
  };

  return function (context) {
    setupSendemailModal(context);
    setupHelptextModal(context);
    setupDataTable(context);
    setupFontAwesome();
  };
}(); //
// setupUser
//


var setupUser = function () {
  return function (context) {// Placeholder for future functionality
  };
}(); //
// setupUserPermission
//


var setupUserPermission = function () {
  var setupModalNew = function setupModalNew(context) {
    $("#modalnewtitle", context).on("hidden.bs.modal", function () {
      $("#newtitle", context).val("");
    });
    $("#modalneworganisation", context).on("hidden.bs.modal", function () {
      $("#neworganisation", context).val("");
    });
  };

  var setupCloneAndRemove = function setupCloneAndRemove(context) {
    $(document, context).on("click", ".cloneme", function () {
      var parent = $(this).parents(".limit-to-view");
      var cloned = parent.clone();
      cloned.removeAttr("id").insertAfter(parent);
    });
    $(document, context).on("click", ".removeme", function () {
      var parent = $(this).parents(".limit-to-view");

      if (parent.siblings(".limit-to-view").length > 0) {
        parent.remove();
      }
    });
  };

  return function (context) {
    setupModalNew(context);
    setupCloneAndRemove(context);
  };
}(); //
// setupView
//


var setupView = function () {
  var setupSelectAll = function setupSelectAll(context) {
    if (!$(".col_check", context).length) return;
    $("#selectall", context).click(function (event) {
      $(".col_check", context).prop("checked", event.currentTarget.checked);
    });
  };

  var setupGlobalChange = function setupGlobalChange(context) {
    $("#global", context).change(function (event) {
      $("#group_id_div", context).toggle(event.currentTarget.checked);
    }).change();
  };

  var setupSorts = function setupSorts(context) {
    var sortsEl = $("div#sorts", context);
    if (!sortsEl.length) return;
    sortsEl.on("click", ".closeme", function (event) {
      var c = $(".request-row").length;
      if (c < 1) return;
      $(event.currentTarget).parents(".request-row").remove();
    });
    sortsEl.on("click", ".add", function (event) {
      $(event.currentTarget).parents(".sort-add").before(sortsEl.data("sortrow"));
    });
  };

  var setupGroups = function setupGroups(context) {
    var groupsEl = $("div#groups", context);
    if (!groupsEl.length) return;
    groupsEl.on("click", ".closeme", function (event) {
      if (!$(".request-row").length) return;
      $(event.currentTarget).parents(".request-row").remove();
    });
    groupsEl.on("click", ".add", function (event) {
      $(event.currentTarget).parents(".group-add").before(groupsEl.data("grouprow"));
    });
  };

  var setupFilter = function setupFilter(context) {
    var builderEl = $("#builder", context);
    if (!builderEl.length) return;
    if (!builderEl.data("use-json")) return;
    var data = base64.decode(builderEl.data("base-filter"));
    builderEl.queryBuilder("setRules", JSON.parse(data));
  };

  var setupUpdateFilter = function setupUpdateFilter(context) {
    $("#saveview", context).click(function () {
      var res = $("#builder", context).queryBuilder("getRules");
      $("#filter", context).val(JSON.stringify(res, null, 2));
    });
  };

  return function (context) {
    setupSelectAll(context);
    setupGlobalChange(context);
    setupSorts(context);
    setupGroups(context);
    setupFilter(context);
    setupUpdateFilter(context);
  };
}();

var setupJSFromContext = function setupJSFromContext(context) {
  var page = $('body').data('page');
  setupBuilder(context);
  setupCalendar(context);
  setupEdit(context);
  setupGlobe(context);

  if (page == "data_graph") {
    setupGraph(context);
  }

  setupLayout(context);
  setupLogin(context);
  setupMetric(context);
  setupMyGraphs(context);
  setupPlaceholder(context);
  setupPopover(context);
  setupPurge(context);
  setupTable(context);
  setupUser(context);
  setupUserPermission(context);
  setupView(context);
};

setupJSFromContext();
