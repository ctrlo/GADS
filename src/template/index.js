if (!Array.prototype.find) {
  Array.prototype.find = function (predicate) {
    // 1. Let O be ? ToObject(this value).
    if (this == null) {
      throw TypeError('"this" is null or not defined');
    }

    var o = Object(this);

    // 2. Let len be ? ToLength(? Get(O, "length")).
    var len = o.length >>> 0;

    // 3. If IsCallable(predicate) is false, throw a TypeError exception.
    if (typeof predicate !== 'function') {
      throw TypeError('predicate must be a function');
    }

    // 4. If thisArg was supplied, let T be thisArg; else let T be undefined.
    var thisArg = arguments[1];

    // 5. Let k be 0.
    var k = 0;

    // 6. Repeat, while k < len
    while (k < len) {
      // a. Let Pk be ! ToString(k).
      // b. Let kValue be ? Get(O, Pk).
      // c. Let testResult be ToBoolean(? Call(predicate, T, « kValue, k, O »)).
      // d. If testResult is true, return kValue.
      var kValue = o[k];
      if (predicate.call(thisArg, kValue, k, o)) {
        return kValue;
      }
      // e. Increase k by 1.
      k++;
    }

    // 7. Return undefined.
    return undefined;
  };
}

if (!Array.prototype.includes) {
  Array.prototype.includes = function(searchElement, fromIndex) {
    if (this == null) {
      throw new TypeError('"this" is null or not defined');
    }

    // 1. Let O be ? ToObject(this value).
    var o = Object(this);

    // 2. Let len be ? ToLength(? Get(O, "length")).
    var len = o.length >>> 0;

    // 3. If len is 0, return false.
    if (len === 0) {
      return false;
    }

    // 4. Let n be ? ToInteger(fromIndex).
    //    (If fromIndex is undefined, this step produces the value 0.)
    var n = fromIndex | 0;

    // 5. If n ≥ 0, then
    //  a. Let k be n.
    // 6. Else n < 0,
    //  a. Let k be len + n.
    //  b. If k < 0, let k be 0.
    var k = Math.max(n >= 0 ? n : len - Math.abs(n), 0);

    function sameValueZero(x, y) {
      return x === y || (typeof x === 'number' && typeof y === 'number' && isNaN(x) && isNaN(y));
    }

    // 7. Repeat, while k < len
    while (k < len) {
      // a. Let elementK be the result of ? Get(O, ! ToString(k)).
      // b. If SameValueZero(searchElement, elementK) is true, return true.
      if (sameValueZero(o[k], searchElement)) {
        return true;
      }
      // c. Increase k by 1.
      k++;
    }

    // 8. Return false
    return false;
  };
}

if (!Array.prototype.map) {
  Array.prototype.map = function (fun /*, thisp */ ) {
    if (this === void 0 || this === null) {
      throw TypeError();
    }

    var t = Object(this);
    var len = t.length >>> 0;
    if (typeof fun !== "function") {
      throw TypeError();
    }

    var res = [];
    res.length = len;
    var thisp = arguments[1],
      i;
    for (i = 0; i < len; i++) {
      if (i in t) {
        res[i] = fun.call(thisp, t[i], i, t);
      }
    }

    return res;
  };
}

if (!Object.keys) {
  Object.keys = function (o) {
    if (o !== Object(o)) {
      throw TypeError('Object.keys called on non-object');
    }
    var ret = [],
      p;
    for (p in o) {
      if (Object.prototype.hasOwnProperty.call(o, p)) {
        ret.push(p);
      }
    }
    return ret;
  };
}

//
// setupFontAwesome
//

const setupFontAwesome = () => {
  if (!window.FontDetect) return;
  if (!FontDetect.isFontLoaded("14px/1 FontAwesome")) {
    $(".use-icon-font").hide();
    $(".use-icon-png").show();
  }
};

//
// setupBuilder
//

const setupBuilder = (() => {
  const buildFilterOperators = type => {
    if (!["date", "daterange"].includes(type)) return undefined;
    const operators = [
      "equal",
      "not_equal",
      "less",
      "less_or_equal",
      "greater",
      "greater_or_equal",
      "is_empty",
      "is_not_empty"
    ];
    type === "daterange" && operators.push("contain");
    return operators;
  };

  const typeaheadProperties = (urlSuffix, layoutId, instanceId) => ({
    input: (container, rule, input_name) =>
      `<input class="typeahead_text" type="text" name="${input_name}_text">
      <input class="typeahead_hidden" type="hidden" name="${input_name}"></input>`,
    valueSetter: ($rule, value, filter, operator, data) => {
      $rule.find(".typeahead_text").val(data.text);
      $rule.find(".typeahead_hidden").val(value);
    },
    onAfterCreateRuleInput: $rule => {
      var $ruleInputText = $(
        `#${$rule.attr("id")} .rule-value-container input[type="text"]`
      );
      var $ruleInputHidden = $(
        `#${$rule.attr("id")} .rule-value-container input[type="hidden"]`
      );
      $ruleInputText.attr("autocomplete", "off");
      $ruleInputText.typeahead({
        delay: 100,
        matcher: function() {
          return true;
        },
        sorter: function(items) {
          return items;
        },
        afterSelect: function(selected) {
          if (typeof selected === "object") {
            $ruleInputHidden.val(selected.id);
          } else {
            $ruleInputHidden.val(selected);
          }
        },
        source: function(query, process) {
          return $.ajax({
            type: "GET",
            url: `/${layoutId}/match/layout/${urlSuffix}`,
            data: { q: query, oi: instanceId },
            success: function(result) {
              process(result);
            },
            dataType: "json"
          });
        }
      });
    }
  });

  const ragProperties = {
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

  const buildFilter = (builderConfig, col) => ({
    id: col.filterId,
    label: col.label,
    type: "string",
    operators: buildFilterOperators(col.type),
    ...(col.type === "rag"
      ? ragProperties
      : col.hasFilterTypeahead
      ? typeaheadProperties(col.urlSuffix, builderConfig.layoutId, col.instanceId)
      : {})
  });

  const makeUpdateFilter = () => {
    window.UpdateFilter = builder => {
      var res = builder.queryBuilder("getRules");
      $("#filter").val(JSON.stringify(res, null, 2));
    };
  };

  const operators = [
    {
      type: "equal",
      accept_values: true,
      apply_to: ["string", "number", "datetime"]
    },
    {
      type: "not_equal",
      accept_values: true,
      apply_to: ["string", "number", "datetime"]
    },
    {
      type: "less",
      accept_values: true,
      apply_to: ["string", "number", "datetime"]
    },
    {
      type: "less_or_equal",
      accept_values: true,
      apply_to: ["string", "number", "datetime"]
    },
    {
      type: "greater",
      accept_values: true,
      apply_to: ["string", "number", "datetime"]
    },
    {
      type: "greater_or_equal",
      accept_values: true,
      apply_to: ["string", "number", "datetime"]
    },
    {
      type: "contains",
      accept_values: true,
      apply_to: ["datetime", "string"]
    },
    {
      type: "not_contains",
      accept_values: true,
      apply_to: ["datetime", "string"]
    },
    { type: "begins_with", accept_values: true, apply_to: ["string"] },
    { type: "not_begins_with", accept_values: true, apply_to: ["string"] },
    {
      type: "is_empty",
      accept_values: false,
      apply_to: ["string", "number", "datetime"]
    },
    {
      type: "is_not_empty",
      accept_values: false,
      apply_to: ["string", "number", "datetime"]
    },
    {
      type: "changed_after",
      nb_inputs: 1,
      accept_values: true,
      multiple: false,
      apply_to: ["string", "number", "datetime"]
    }
  ];

  const setupBuilder = builderEl => {
    const builderConfig = JSON.parse($(builderEl).html());
    if (builderConfig.filterNotDone) makeUpdateFilter();

    $(`#builder${builderConfig.builderId}`).queryBuilder({
      showPreviousValues: builderConfig.showPreviousValues,
      filters: builderConfig.filters.map(col => buildFilter(builderConfig, col)),
      operators,
      lang: {
        operators: {
          changed_after: "changed on or after"
        }
      }
    });
  };

  const setupAllBuilders = context => {
    $('script[id^="builder_json_"]', context).each((i, builderEl) => {
      setupBuilder(builderEl);
    });
  };

  const setupTypeahead = context => {
    $(document, context).on("input", ".typeahead_text", function() {
      var value = $(this).val();
      $(this)
        .next(".typeahead_hidden")
        .val(value);
    });
  };

  return context => {
    setupAllBuilders(context);
    setupTypeahead(context);
  };
})();

//
// setupCalendar
//

const setupCalendar = (() => {
  const initCalendar = context => {
    var calendarEl = $("#calendar", context);
    if (!calendarEl.length) return false;

    var options = {
      events_source: `/${calendarEl.attr(
        "data-event-source"
      )}/data_calendar/${new Date().getTime()}`,
      view: calendarEl.data("view"),
      tmpl_path: "/tmpls/",
      tmpl_cache: false,
      onAfterEventsLoad: function(events) {
        if (!events) {
          return;
        }
        var list = $("#eventlist");
        list.html("");

        $.each(events, function(key, val) {
          $(document.createElement("li"))
            .html(`<a href="${val.url}">${val.title}</a>`)
            .appendTo(list);
        });
      },
      onAfterViewLoad: function(view) {
        $("#caltitle").text(this.getTitle());
        $(".btn-group button").removeClass("active");
        $(`button[data-calendar-view="${view}"]`).addClass("active");
      },
      classes: {
        months: {
          general: "label"
        }
      }
    };

    const day = calendarEl.data("calendar-day-ymd");
    if (day) {
      options.day = day;
    }

    return calendarEl.calendar(options);
  };

  const setupButtons = (calendar, context) => {
    $(".btn-group button[data-calendar-nav]", context).each(function() {
      var $this = $(this);
      $this.click(function() {
        calendar.navigate($this.data("calendar-nav"));
      });
    });

    $(".btn-group button[data-calendar-view]", context).each(function() {
      var $this = $(this);
      $this.click(function() {
        calendar.view($this.data("calendar-view"));
      });
    });
  };

  const setupSpecifics = (calendar, context) => {
    $("#first_day", context).change(function() {
      var value = $(this).val();
      value = value.length ? parseInt(value) : null;
      calendar.setOptions({ first_day: value });
      calendar.view();
    });

    $("#language", context).change(function() {
      calendar.setLanguage($(this).val());
      calendar.view();
    });

    $("#events-in-modal", context).change(function() {
      var val = $(this).is(":checked") ? $(this).val() : null;
      calendar.setOptions({ modal: val });
    });
    $("#events-modal .modal-header, #events-modal .modal-footer", context).click(
      function() {}
    );
  };

  return context => {
    const calendar = initCalendar(context);
    if (calendar) {
      setupButtons(calendar, context);
      setupSpecifics(calendar, context);
      setupFontAwesome();
    }
  };
})()

//
// setupCurvalModal
//

const setupCurvalModal = (() => {
  const curvalModalValidationSucceeded = (form, values, context) => {
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
      jQuery.map(modal_field_ids, function(element) {
        var control = form.find('[data-column-id="' + element + '"]');
        var value = getFieldValues(control);
        value = values["field" + element];
        value = $("<div />", context)
          .text(value)
          .html();
        row_cells.append(
          $('<td class="curval-inner-text">', context).append(value)
        );
      });
      var links = $(
        `<td>
        <a class="curval-modal" style="cursor:pointer" data-layout-id="${col_id} data-instance-name=${instance_name}>edit</a> | <a class="curval_remove" style="cursor:pointer">remove</a>
      </td>`,
        context
      );
      row_cells.append(links.append(hidden_input));
      if (guid) {
        var hidden = $('input[data-guid="' + guid + '"]', context).val(form_data);
        hidden.closest(".curval_item").replaceWith(row_cells);
      } else {
        $(`#curval_list_${col_id}`, context)
          .find("tbody")
          .prepend(row_cells);
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

      var textValue = jQuery
        .map(modal_field_ids, function(element) {
          var value = values["field" + element];
          return $("<div />")
            .text(value)
            .html();
        })
        .join(", ");

      guid = window.guid();
      const id = `field${col_id}_${guid}`;
      var deleteButton = multi
        ? '<button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete" title="delete" tabindex="-1">&times;</button>'
        : "";
      $search.before(
        `<li data-list-item="${id}">${textValue}${deleteButton}</li>`
      );
      var inputType = multi ? "checkbox" : "radio";
      $answersList.append(`<li class="answer">
        <span class="control">
            <label id="${id}_label" for="${id}">
                <input id="${id}" name="field${col_id}" type="${inputType}" value="${form_data}" class="${
        multi ? "" : "visually-hidden"
      }" checked aria-labelledby="${id}_label">
                <span>${textValue}</span>
            </label>
        </span>
        <span class="details">
            <a class="curval_remove" style="cursor:pointer">remove</a>
        </span>
      </li>`);

      /* Reinitialize widget */
      setupSelectWidgets($formGroup);
    } else if (valueSelector === "typeahead") {
      var $hiddenInput = $formGroup.find(`input[name=field${col_id}]`);
      var $typeaheadInput = $formGroup.find(
        `input[name=field${col_id}_typeahead]`
      );

      var textValueHead = jQuery
        .map(modal_field_ids, function(element) {
          var value = values["field" + element];
          return $("<div />")
            .text(value)
            .html();
        })
        .join(", ");

      $hiddenInput.val(form_data);
      $typeaheadInput.val(textValueHead);
    }

    $(".modal.in", context).modal("hide");
  };

  const curvalModalValidationFailed = (form, errorMessage) => {
    form
      .find(".alert")
      .text(errorMessage)
      .removeAttr("hidden");
    form
      .parents(".modal-content")
      .get(0)
      .scrollIntoView();
    form.find("button[type=submit]").prop("disabled", false);
  };

  const setupAddButton = context => {
    $(document, context).on("mousedown", ".curval-modal", function(e) {
      var layout_id = $(e.target).data("layout-id");
      var instance_name = $(e.target).data("instance-name");
      var current_id = $(e.target).data("current-id");
      var hidden = $(e.target)
        .closest(".curval_item")
        .find(`input[name=field${layout_id}]`);
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
      var url = current_id
        ? `/record/${current_id}`
        : `/${instance_name}/record/`;
      m.find(".modal-body").load(
        `${url}?include_draft&modal=${layout_id}&${form_data}`,
        function() {
          if (mode === "edit") {
            m.find("form").data("guid", guid);
          }
          Linkspace.init(m);
        }
      );
      m.on("focus", ".datepicker", function() {
        $(this).datepicker({
          format: m.attr("data-dateformat-datepicker"),
          autoclose: true
        });
      });
      m.modal();
    });
  };

  const setupSubmit = context => {
    $("#curval_modal", context).on("submit", ".curval-edit-form", function(e) {
      e.preventDefault();
      var form = $(this);
      var form_data = form.serialize();

      form.addClass("edit-form--validating");
      form.find(".alert").attr("hidden", "");

      $.post(
        form.attr("action") + "?validate&include_draft",
        form_data,
        function(data) {
          if (data.error === 0) {
            curvalModalValidationSucceeded(form, data.values);
          } else {
            var errorMessage =
              data.error === 1 ? data.message : "Oops! Something went wrong.";
            curvalModalValidationFailed(form, errorMessage);
          }
        },
        "json"
      )
        .fail(function(jqXHR, textstatus, errorthrown) {
          var errorMessage = `Oops! Something went wrong: ${textstatus}: ${errorthrown}`;
          curvalModalValidationFailed(form, errorMessage);
        })
        .always(function() {
          form.removeClass("edit-form--validating");
        });
    });
  };

  const setupRemoveCurval = context => {
    $(".curval_group", context).on("click", ".curval_remove", function() {
      $(this)
        .closest(".curval_item")
        .remove();
    });

    $(".select-widget", context).on("click", ".curval_remove", function() {
      var fieldId = $(this)
        .closest(".answer")
        .find("input")
        .prop("id");
      $(this)
        .closest(".select-widget")
        .find(`.current li[data-list-item=${fieldId}]`)
        .remove();
      $(this)
        .closest(".answer")
        .remove();
    });
  };

  return context => {
    setupAddButton(context);
    setupSubmit(context);
    setupRemoveCurval(context);
  };
})()

//
// setupDatePicker
//

const setupDatePicker = (() => {
  const setupDatePickers = context => {
    $(".datepicker", context).datepicker({
      format: $(document.body).data("config-dataformat-datepicker"),
      autoclose: true
    });
  };

  const setupDateRange = context => {
    $(".input-daterange input.from", context).each(function() {
      $(this).on("changeDate", function() {
        var toDatepicker = $(this)
          .parents(".input-daterange")
          .find(".datepicker.to");
        if (!toDatepicker.val()) {
          toDatepicker.datepicker("update", $(this).datepicker("getDate"));
        }
      });
    });
  };

  const setupRemoveDatePicker = context => {
    $(document, context).on("click", ".remove_datepicker", function() {
      var dp = ".datepicker" + $(this).data("field");
      $(dp).datepicker("destroy");
      //eslint-disable-next-line no-alert
      alert("Date selector has been disabled for this field");
    });
  };

  return context => {
    setupDatePickers(context);
    setupDateRange(context);
    setupRemoveDatePicker(context);
  };
})()

//
// setupEdit
//

const setupEdit = (() => {
  const setupCloneAndRemove = context => {
    $(document, context).on("click", ".cloneme", function() {
      var parent = $(this).parents(".input_holder");
      var cloned = parent.clone();
      cloned.removeAttr("id").insertAfter(parent);
      cloned.find(":text").val("");
      cloned.find(".datepicker").datepicker({
        format: parent.attr("data-dateformat-datepicker"),
        autoclose: true
      });
    });
    $(document, context).on("click", ".removeme", function() {
      var parent = $(this).parents(".input_holder");
      if (parent.siblings(".input_holder").length > 0) {
        parent.remove();
      }
    });
  };

  const setupHelpTextModal = context => {
    $("#helptext_modal", context).on("show.bs.modal", function(e) {
      var loadurl = $(e.relatedTarget).data("load-url");
      $(this)
        .find(".modal-body")
        .load(loadurl);
    });

    $(document, context).on("click", ".more-info", function(e) {
      var record_id = $(e.target).data("record-id");
      var m = $("#readmore_modal", context);
      m.find(".modal-body").text("Loading...");
      m.find(".modal-body").load("/record_body/" + record_id);

      /* Trigger focus restoration on modal close */
      m.one("show.bs.modal", function(showEvent) {
        /* Only register focus restorer if modal will actually get shown */
        if (showEvent.isDefaultPrevented()) {
          return;
        }
        m.one("hidden.bs.modal", function() {
          $(e.target, context).is(":visible") &&
            $(e.target, context).trigger("focus");
        });
      });

      /* Stop propagation of the escape key, as may have side effects, like closing select widgets. */
      m.one("keyup", function(e) {
        if (e.keyCode == 27) {
          e.stopPropagation();
        }
      });

      m.modal();
    });
  };

  const setupTypeahead = context => {
    $('input[type="text"][id^="typeahead_"]', context).each((i, typeaheadEl) => {
      $(typeaheadEl, context).change(function() {
        if (!$(this).val()) {
          $(`#${typeaheadEl.id}_value`, context).val("");
        }
      });
      $(typeaheadEl, context).typeahead({
        delay: 500,
        matcher: function() {
          return true;
        },
        sorter: function(items) {
          return items;
        },
        afterSelect: function(selected) {
          $(`#${typeaheadEl.id}_value`, context).val(selected.id);
        },
        source: function(query, process) {
          return $.ajax({
            type: "GET",
            url: `/${$(typeaheadEl, context).data("layout-id")}/match/layout/${$(
              typeaheadEl
            ).data("typeahead-id")}`,
            data: { q: query },
            success: function(result) {
              process(result);
            },
            dataType: "json"
          });
        }
      });
    });
  };

  return context => {
    setupCloneAndRemove(context);
    setupHelpTextModal(context);
    setupCurvalModal(context);
    setupDatePicker(context);
    setupTypeahead(context);
  };
})()

//
// setupGlobe
//

const setupGlobe = (() => {
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

// setupGraph

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
    initGraph(context);
  };
})()

//
// setupLayout
//

const setupLayout = (() => {
  const setupDemoButtons = context => {
    const demo_delete = () => {
      var ref = $("#jstree_demo_div", context).jstree(true),
        sel = ref.get_selected();
      if (!sel.length) {
        return false;
      }
      ref.delete_node(sel);
    };

    $("#btnDeleteNode", context).click(demo_delete);

    const demo_create = () => {
      var ref = $("#jstree_demo_div", context).jstree(true),
        sel = ref.get_selected();
      if (sel.length) {
        sel = sel[0];
      } else {
        sel = "#";
      }
      sel = ref.create_node(sel, { type: "file" });
      if (sel) {
        ref.edit(sel);
      }
    };

    $("#btnAddNode", context).click(demo_create);

    const demo_rename = () => {
      var ref = $("#jstree_demo_div", context).jstree(true),
        sel = ref.get_selected();
      if (!sel.length) {
        return false;
      }
      sel = sel[0];
      ref.edit(sel);
    };

    $("#btnRenameNode", context).click(demo_rename);
  };

  // No longer used? Where is #selectall ?
  const setupSelectAll = context => {
    $("#selectall", context).click(() => {
      if ($(".check_perm:checked", context).length == 7) {
        $(".check_perm", context).prop("checked", false);
      } else {
        $(".check_perm", context).prop("checked", true);
      }
    });
  };

  const setupSortableHandle = context => {
    if (!$(".sortable", context).length) return;
    $(".sortable", context).sortable({
      handle: ".drag"
    });
  };

  const setupTreeDemo = context => {
    const treeEl = $("#jstree_demo_div", context);
    if (!treeEl.length) return;
    treeEl.jstree({
      core: {
        check_callback: true,
        force_text: true,
        themes: { stripes: true },
        data: {
          url: () =>
            `/${treeEl.data(
              "layout-identifier"
            )}/tree${new Date().getTime()}/${treeEl.data("column-id")}?`,
          data: node => ({ id: node.id })
        }
      }
    });
  };

  const setupDropdownValues = context => {
    $("div#legs", context).on("click", ".add", event => {
      $(event.currentTarget, context)
        .closest("#legs")
        .find(".sortable").append(`
          <div class="request-row">
            <p>
              <input type="hidden" name="enumval_id">
              <input type="text" class="form-control" style="width:80%; display:inline" name="enumval">
              <button type="button" class="close closeme" style="float:none">&times;</button>
              <span class="fa fa-hand-paper-o fa-lg use-icon-font close drag" style="float:none"></span>
            </p>
          </div>
      `);
      $(".sortable", context).sortable("refresh");
    });
    $("div#legs").on("click", ".closeme", event => {
      var count = $(".request-row", context).length;
      if (count < 2) return;
      $(event.currentTarget, context)
        .parents(".request-row")
        .remove();
    });
  };

  const setupTableDropdown = context => {
    $("#refers_to_instance_id", context).change(event => {
      var divid = `#instance_fields_${$(event.currentTarget, context).val()}`;
      $(".instance_fields", context).hide();
      $(divid, context).show();
    });
  };

  const setupAutoValueField = context => {
    $("#related_field_id", context).change(event => {
      var divid = $(event.currentTarget)
        .find(":selected")
        .data("instance_id");
      $(".autocur_instance", context).hide();
      $(`#autocur_instance_${divid}`, context).show();
    });

    $("#filval_related_field_id", context).change(function() {
      var divid = $(this).val();
      $(".filval_curval", context).hide();
      $("#filval_curval_" + divid, context).show();
    });
  };

  const setupJsonFilters = context => {
    $('div[id^="builder"]', context).each((i, builderEl) => {
      const filterBase = $(builderEl).data("filter-base");
      if (!filterBase) return;
      var data = base64.decode(filterBase);
      $(builderEl).queryBuilder("setRules", JSON.parse(data));
    });
  };

  const setupDisplayConditionsBuilder = context => {
    const conditionsBuilder = $("#displayConditionsBuilder", context);
    if (!conditionsBuilder.length) return;
    const builderData = conditionsBuilder.data();
    conditionsBuilder.queryBuilder({
      filters: builderData.filters,
      allow_groups: 0,
      operators: [
        { type: "equal", accept_values: true, apply_to: ["string"] },
        { type: "contains", accept_values: true, apply_to: ["string"] },
        { type: "not_equal", accept_values: true, apply_to: ["string"] },
        { type: "not_contains", accept_values: true, apply_to: ["string"] }
      ]
    });
    if (builderData.filterBase) {
      const data = base64.decode(builderData.filterBase);
      conditionsBuilder.queryBuilder("setRules", JSON.parse(data));
    }
  };

  const setupSubmitSave = context => {
    $("#submit_save", context).click(function() {
      const res = $("#displayConditionsBuilder", context).queryBuilder(
        "getRules"
      );
      $("#displayConditions", context).val(JSON.stringify(res, null, 2));

      const current_builder = `#builder${$(
        "#refers_to_instance_id",
        context
      ).val()}`;
      const jstreeDemoDivEl = $("#jstree_demo_div", context);
      if (jstreeDemoDivEl.length && jstreeDemoDivEl.is(":visible")) {
        const v = jstreeDemoDivEl.jstree(true).get_json("#", { flat: false });
        const mytext = JSON.stringify(v);
        const data = jstreeDemoDivEl.data();
        $.ajax({
          async: false,
          type: "POST",
          url: `/${data.layoutIdentifier}/tree/${data.columnId}`,
          data: { data: mytext, csrf_token: data.csrfToken }
        }).done(() => {
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

  const setupType = context => {
    $("#type", context)
      .on("change", function() {
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
      })
      .trigger("change");
  };

  const setupNotify = context => {
    $("#notify_on_selection", context)
      .on("change", function() {
        if ($(this).prop('checked')) {
          $("#notify-options", context).show();
        } else {
          $("#notify-options", context).hide();
        }
      })
      .trigger("change");
  };

  return context => {
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
    setupNotify(context);
  };
})()

//
// setupLogin
//

const setupLogin = (() => {
  const setupOpenModalOnLoad = (id, context) => {
    const modalEl = $(id, context);
    if (modalEl.data("open-on-load")) {
      modalEl.modal("show");
    }
  };

  return context => {
    setupOpenModalOnLoad("#modalregister", context);
    setupOpenModalOnLoad("#modal-reset-password", context);
  };
})()

//
// setupMetric
//

const setupMetric = (() => {
  const setupMetricModal = context => {
    const modalEl = $("#modal_metric", context);
    if (!modalEl.length) return;
    modalEl.on("show.bs.modal", event => {
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

  return context => {
    setupMetricModal(context);
  };
})()

//
// setupMyGraphs
//

const setupMyGraphs = (() => {
  const setupDataTable = context => {
    const dtableEl = $("#mygraphs-table", context);
    if (!dtableEl.length) return;
    dtableEl.dataTable({
      columnDefs: [
        {
          targets: 0,
          orderable: false
        }
      ],
      pageLength: 50,
      order: [[1, "asc"]]
    });
  };

  return context => {
    setupDataTable(context);
  };
})()

//
// setupPlaceholder
//

const setupPlaceholder = (() => {
  const setupPlaceholder = context => {
    $("input, text", context).placeholder();
  };

  return context => {
    setupPlaceholder(context);
  };
})()

//
// setupPopover
//

const setupPopover = (() => {
  const setupPopover = context => {
    $('[data-toggle="popover"]', context).popover({
      placement: "auto",
      html: true
    });
  };

  return context => {
    setupPopover(context);
  };
})()

//
// setupPurge
//

const setupPurge = (() => {
  const setupSelectAll = context => {
    $("#selectall", context).click(function() {
      $(".record_selected", context).prop("checked", this.checked);
    });
  };

  return context => {
    setupSelectAll(context);
  };
})()

//
// setupTable
//

const setupTable = (() => {
  const setupSendemailModal = context => {
    $("#modal_sendemail", context).on("show.bs.modal", event => {
      var button = $(event.relatedTarget);
      var peopcol_id = button.data("peopcol_id");
      $("#modal_sendemail_peopcol_id").val(peopcol_id);
    });
  };

  const setupHelptextModal = context => {
    $("#modal_helptext", context).on("show.bs.modal", event => {
      var button = $(event.relatedTarget);
      var col_name = button.data("col_name");
      $("#modal_helptext", context)
        .find(".modal-title")
        .text(col_name);
      var col_id = button.data("col_id");
      $.get("/helptext/" + col_id, data => {
        $("#modal_helptext", context)
          .find(".modal-body")
          .html(data);
      });
    });
  };

  const setupDataTable = context => {
    if (!$("#data-table", context).length) return;
    $("#data-table", context).floatThead({
      floatContainerCss: {},
      zIndex: () => 999,
      ariaLabel: ($table, $headerCell) => $headerCell.data("thlabel")
    });
  };

  return context => {
    setupSendemailModal(context);
    setupHelptextModal(context);
    setupDataTable(context);
    setupFontAwesome();
  };
})()

//
// setupUser
//

const setupUser = (() => {
  return context => {
    // Placeholder for future functionality
  };
})()

//
// setupUserPermission
//

const setupUserPermission = (() => {
  const setupModalNew = context => {
    $("#modalnewtitle", context).on("hidden.bs.modal", () => {
      $("#newtitle", context).val("");
    });
    $("#modalneworganisation", context).on("hidden.bs.modal", () => {
      $("#neworganisation", context).val("");
    });
  };

  const setupCloneAndRemove = context => {
    $(document, context).on("click", ".cloneme", function() {
      var parent = $(this).parents(".limit-to-view");
      var cloned = parent.clone();
      cloned.removeAttr("id").insertAfter(parent);
    });
    $(document, context).on("click", ".removeme", function() {
      var parent = $(this).parents(".limit-to-view");
      if (parent.siblings(".limit-to-view").length > 0) {
        parent.remove();
      }
    });
  };

  return context => {
    setupModalNew(context);
    setupCloneAndRemove(context);
  };
})()

//
// setupView
//

const setupView = (() => {
  const setupSelectAll = context => {
    if (!$(".col_check", context).length) return;
    $("#selectall", context).click(event => {
      $(".col_check", context).prop("checked", event.currentTarget.checked);
    });
  };

  const setupGlobalChange = context => {
    $("#global", context)
      .change(event => {
        $("#group_id_div", context).toggle(event.currentTarget.checked);
      })
      .change();
  };

  const setupSorts = context => {
    const sortsEl = $("div#sorts", context);
    if (!sortsEl.length) return;
    sortsEl.on("click", ".closeme", event => {
      var c = $(".request-row").length;
      if (c < 1) return;
      $(event.currentTarget)
        .parents(".request-row")
        .remove();
    });
    sortsEl.on("click", ".add", event => {
      $(event.currentTarget)
        .parents(".sort-add")
        .before(sortsEl.data("sortrow"));
    });
  };

  const setupGroups = context => {
    const groupsEl = $("div#groups", context);
    if (!groupsEl.length) return;

    groupsEl.on("click", ".closeme", event => {
      if (!$(".request-row").length) return;
      $(event.currentTarget)
        .parents(".request-row")
        .remove();
    });
    groupsEl.on("click", ".add", event => {
      $(event.currentTarget)
        .parents(".group-add")
        .before(groupsEl.data("grouprow"));
    });
  };

  const setupFilter = context => {
    const builderEl = $("#builder", context);
    if (!builderEl.length) return;
    if (!builderEl.data("use-json")) return;
    var data = base64.decode(builderEl.data("base-filter"));
    builderEl.queryBuilder("setRules", JSON.parse(data));
  };

  const setupUpdateFilter = context => {
    $("#saveview", context).click(() => {
      var res = $("#builder", context).queryBuilder("getRules");
      $("#filter", context).val(JSON.stringify(res, null, 2));
    });
  };

  return context => {
    setupSelectAll(context);
    setupGlobalChange(context);
    setupSorts(context);
    setupGroups(context);
    setupFilter(context);
    setupUpdateFilter(context);
  };
})()

const setupJSFromContext = context => {

  var page = $('body').data('page');

  setupBuilder(context);
  setupCalendar(context);
  setupEdit(context);
  setupGlobe(context);
  if (page == "data_graph") {
      $(document).ready(function(){ // jqplot does not work in IE8 unless in document.ready
          setupGraph(context);
      });
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
