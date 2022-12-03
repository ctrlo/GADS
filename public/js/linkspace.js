(function () {
  'use strict';

  if (!Array.prototype.filter) {
    // eslint-disable-next-line no-extend-native
    Array.prototype.filter = function (fun
    /*, thisp */
    ) {
      if (this === void 0 || this === null) throw new TypeError();
      var t = Object(this);
      var len = t.length >>> 0;
      if (typeof fun !== "function") throw new TypeError();
      var res = [];
      var thisp = arguments[1];

      for (var i = 0; i < len; i++) {
        if (i in t) {
          var val = t[i]; // in case fun mutates this

          if (fun.call(thisp, val, i, t)) res.push(val);
        }
      }

      return res;
    };
  }

  if (!Array.prototype.find) {
    // eslint-disable-next-line no-extend-native
    Array.prototype.find = function (predicate) {
      // 1. Let O be ? ToObject(this value).
      if (this == null) {
        throw TypeError('"this" is null or not defined');
      }

      var o = Object(this); // 2. Let len be ? ToLength(? Get(O, "length")).

      var len = o.length >>> 0; // 3. If IsCallable(predicate) is false, throw a TypeError exception.

      if (typeof predicate !== "function") {
        throw TypeError("predicate must be a function");
      } // 4. If thisArg was supplied, let T be thisArg; else let T be undefined.


      var thisArg = arguments[1]; // 5. Let k be 0.

      var k = 0; // 6. Repeat, while k < len

      while (k < len) {
        // a. Let Pk be ! ToString(k).
        // b. Let kValue be ? Get(O, Pk).
        // c. Let testResult be ToBoolean(? Call(predicate, T, « kValue, k, O »)).
        // d. If testResult is true, return kValue.
        var kValue = o[k];

        if (predicate.call(thisArg, kValue, k, o)) {
          return kValue;
        } // e. Increase k by 1.


        k++;
      } // 7. Return undefined.


      return undefined;
    };
  }

  if (typeof Array.prototype.forEach != "function") {
    // eslint-disable-next-line no-extend-native
    Array.prototype.forEach = function (callback) {
      for (var i = 0; i < this.length; i++) {
        callback.apply(this, [this[i], i, this]);
      }
    };
  }

  if (!Array.prototype.includes) {
    // eslint-disable-next-line no-extend-native
    Array.prototype.includes = function (searchElement, fromIndex) {
      if (this == null) {
        throw new TypeError('"this" is null or not defined');
      } // 1. Let O be ? ToObject(this value).


      var o = Object(this); // 2. Let len be ? ToLength(? Get(O, "length")).

      var len = o.length >>> 0; // 3. If len is 0, return false.

      if (len === 0) {
        return false;
      } // 4. Let n be ? ToInteger(fromIndex).
      //    (If fromIndex is undefined, this step produces the value 0.)


      var n = fromIndex | 0; // 5. If n ≥ 0, then
      //  a. Let k be n.
      // 6. Else n < 0,
      //  a. Let k be len + n.
      //  b. If k < 0, let k be 0.

      var k = Math.max(n >= 0 ? n : len - Math.abs(n), 0);

      var sameValueZero = function sameValueZero(x, y) {
        return x === y || typeof x === "number" && typeof y === "number" && isNaN(x) && isNaN(y);
      }; // 7. Repeat, while k < len


      while (k < len) {
        // a. Let elementK be the result of ? Get(O, ! ToString(k)).
        // b. If SameValueZero(searchElement, elementK) is true, return true.
        if (sameValueZero(o[k], searchElement)) {
          return true;
        } // c. Increase k by 1.


        k++;
      } // 8. Return false


      return false;
    };
  }

  if (!Array.prototype.map) {
    // eslint-disable-next-line no-extend-native
    Array.prototype.map = function (fun
    /*, thisp */
    ) {
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

  if (!Array.prototype.some) {
    // eslint-disable-next-line no-extend-native
    Array.prototype.some = function (fun, thisArg) {

      if (this == null) {
        throw new TypeError("Array.prototype.some called on null or undefined");
      }

      if (typeof fun !== "function") {
        throw new TypeError();
      }

      var t = Object(this);
      var len = t.length >>> 0;

      for (var i = 0; i < len; i++) {
        if (i in t && fun.call(thisArg, t[i], i, t)) {
          return true;
        }
      }

      return false;
    };
  }

  if (!Function.prototype.bind) {
    // eslint-disable-next-line no-extend-native
    Function.prototype.bind = function (oThis) {
      if (typeof this !== "function") {
        // closest thing possible to the ECMAScript 5 internal IsCallable function
        throw new TypeError("Function.prototype.bind - what is trying to be bound is not callable");
      }

      var aArgs = Array.prototype.slice.call(arguments, 1),
          fToBind = this,
          fNOP = function fNOP() {},
          fBound = function fBound() {
        return fToBind.apply(this instanceof fNOP && oThis ? this : oThis, aArgs.concat(Array.prototype.slice.call(arguments)));
      };

      fNOP.prototype = this.prototype;
      fBound.prototype = new fNOP();
      return fBound;
    };
  }

  if (!Object.keys) {
    Object.keys = function (o) {
      if (o !== Object(o)) {
        throw TypeError("Object.keys called on non-object");
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

  // This wrapper fixes wrong placement of datepicker. See
  // https://github.com/uxsolutions/bootstrap-datepicker/issues/1941
  var originaldatepicker = $.fn.datepicker;

  $.fn.datepicker = function () {
    var result = originaldatepicker.apply(this, arguments);
    this.on("show", function () {
      var $target = $(this),
          $picker = $target.data("datepicker").picker,
          top;

      if ($picker.hasClass("datepicker-orient-top")) {
        top = $target.offset().top - $picker.outerHeight() - parseInt($picker.css("marginTop"));
      } else {
        top = $target.offset().top + $target.outerHeight() + parseInt($picker.css("marginTop"));
      }

      $picker.offset({
        top: top
      });
    });
    return result;
  };

  var setupAccessibility = function () {
    var setupAccessibility = function setupAccessibility(context) {
      $("a[role=button]", context).on("keypress", function (e) {
        if (e.keyCode === 32) {
          // SPACE
          this.click();
        }
      });
      var $navbar = $(".navbar-fixed-bottom", context);

      if ($navbar.length) {
        $(".edit-form .form-group", context).on("focusin", function (e) {
          var $el = $(e.target);
          var elTop = $el.offset().top;
          var elBottom = elTop + $el.outerHeight();
          var navbarTop = $navbar.offset().top;

          if (elBottom > navbarTop) {
            $("html, body").animate({
              scrollTop: $(window).scrollTop() + elBottom - navbarTop + 20
            }, 300);
          }
        });
      }
    };

    return function (context) {
      setupAccessibility(context);
    };
  }();

  function _defineProperty(obj, key, value) {
    if (key in obj) {
      Object.defineProperty(obj, key, {
        value: value,
        enumerable: true,
        configurable: true,
        writable: true
      });
    } else {
      obj[key] = value;
    }

    return obj;
  }

  function ownKeys(object, enumerableOnly) {
    var keys = Object.keys(object);

    if (Object.getOwnPropertySymbols) {
      var symbols = Object.getOwnPropertySymbols(object);
      if (enumerableOnly) symbols = symbols.filter(function (sym) {
        return Object.getOwnPropertyDescriptor(object, sym).enumerable;
      });
      keys.push.apply(keys, symbols);
    }

    return keys;
  }

  function _objectSpread2(target) {
    for (var i = 1; i < arguments.length; i++) {
      var source = arguments[i] != null ? arguments[i] : {};

      if (i % 2) {
        ownKeys(Object(source), true).forEach(function (key) {
          _defineProperty(target, key, source[key]);
        });
      } else if (Object.getOwnPropertyDescriptors) {
        Object.defineProperties(target, Object.getOwnPropertyDescriptors(source));
      } else {
        ownKeys(Object(source)).forEach(function (key) {
          Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key));
        });
      }
    }

    return target;
  }

  var setupBuilder = function () {
    var buildFilterOperators = function buildFilterOperators(type) {
      if (!["date", "daterange", "createddate", "createdby", "intgr"].includes(type)) return undefined;
      var operators = ["equal", "not_equal", "less", "less_or_equal", "greater", "greater_or_equal"];
      if (type === "createddate") return operators;
      type === "daterange" && operators.push("contains");

      if (type === "createdby") {
        operators.push("contains", "not_contains", "begins_with", "not_begins_with");
      } else {
        operators.push("is_empty", "is_not_empty", "changed_after");
      }

      return operators;
    };

    var typeaheadProperties = function typeaheadProperties(urlSuffix, layoutId, instanceId, useIdInFilter) {
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
            displayText: function displayText(item) {
              return item.label;
            },
            afterSelect: function afterSelect(selected) {
              if (useIdInFilter) {
                $ruleInputHidden.val(selected.id);
              } else {
                $ruleInputHidden.val(selected.label);
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
                  process(result.records);
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
      return _objectSpread2({
        id: col.filterId,
        label: col.label,
        type: "string",
        operators: buildFilterOperators(col.type)
      }, col.type === "rag" ? ragProperties : col.hasFilterTypeahead ? typeaheadProperties(col.urlSuffix, builderConfig.layoutId, col.instanceId, col.useIdInFilter) : {});
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
      if (!builderConfig.filters.length) return;
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
  }();

  var setupFontAwesome = function setupFontAwesome() {
    if (!window.FontDetect) return;

    if (!FontDetect.isFontLoaded("14px/1 FontAwesome")) {
      $(".use-icon-font").hide();
      $(".use-icon-png").show();
    }
  };

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
  }();

  var setupColumnFilters = function () {
    var getParams = function getParams(options) {
      if (!options) {
        options = {};
      } // IE11 compat


      return _.chain(location.search.slice(1).split("&")).map(function (item) {
        if (item) {
          return item.split("=");
        }

        return undefined;
      }).compact().value().filter(function (param) {
        return param[0] !== options.except;
      });
    };

    var setupColumnFilters = function setupColumnFilters(context) {
      $(".column-filter", context).each(function () {
        var $columnFilter = $(this);
        var colId = $columnFilter.data("col-id");
        var autocompleteEndpoint = $columnFilter.data("autocomplete-endpoint");
        var autocompleteHasID = $columnFilter.data("autocomplete-has-id");
        var values = $columnFilter.data("values") || [];
        var $error = $columnFilter.find(".column-filter__error");
        var $searchInput = $columnFilter.find(".column-filter__search-input");
        var $clearSearchInput = $columnFilter.find(".column-filter__clear-search-input");
        var $spinner = $columnFilter.find(".column-filter__spinner");
        var $values = $columnFilter.find(".column-filter__values");
        var $submit = $columnFilter.find(".column-filter__submit");

        var searchQ = function searchQ() {
          return $searchInput.length ? $searchInput.val() : "";
        }; // Values are sorted when we've got a search input field, so additional values
        // received from the API are sorted amongst currently available values.


        var sortValues = function sortValues() {
          return $searchInput.length === 1;
        };

        var renderValue = function renderValue(value, index) {
          var uniquePrefix = "column_filter_value_label_" + colId + "_" + index;
          return $('<li class="column-filter__value">' + '<label id="' + uniquePrefix + '_label" for="' + uniquePrefix + '">' + '<input id="' + uniquePrefix + '" type="checkbox" value="' + value.id + '" ' + (value.checked ? "checked" : "") + ' aria-labelledby="' + uniquePrefix + '_label">' + '<span role="option">' + value.value + "</span>" + "</label>" + "</li>");
        };

        var renderValues = function renderValues() {
          var q = searchQ();
          $values.empty();

          var filteredValues = _.filter(values, function (value) {
            return value.value.toLowerCase().indexOf(q.toLowerCase()) > -1;
          });

          var sortedAndFilteredValues = sortValues() ? _.sortBy(filteredValues, "value") : filteredValues;

          _.each(sortedAndFilteredValues, function (value, index) {
            $values.append(renderValue(value, index));
          });
        };

        var onEmptySearch = function onEmptySearch() {
          $error.attr("hidden", "");
          renderValues();
        };

        var fetchValues = _.debounce(function () {
          var q = searchQ();

          if (!q.length) {
            onEmptySearch();
            return;
          }

          $error.attr("hidden", "");
          $spinner.removeAttr("hidden");
          $.getJSON(autocompleteEndpoint + q, function (data) {
            _.each(data.records, function (searchValue) {
              if (autocompleteHasID) {
                if (!_.some(values, function (value) {
                  return value.id === searchValue.id.toString();
                })) {
                  values.push({
                    id: searchValue.id.toString(),
                    value: searchValue.label
                  });
                }
              } else {
                values.push({
                  value: searchValue
                });
              }
            });
          }).fail(function (jqXHR, textStatus, textError) {
            $error.text(textError);
            $error.removeAttr("hidden");
          }).always(function () {
            $spinner.attr("hidden", "");
            renderValues();
          });
        }, 250);

        $values.delegate("input", "change", function () {
          var checkboxValue = $(this).val();

          var valueIndex = _.findIndex(values, function (value) {
            return value.id === checkboxValue;
          });

          values[valueIndex].checked = this.checked;
        });
        $searchInput.on("keyup", function () {
          var val = $(this).val();

          if (val.length) {
            $clearSearchInput.removeAttr("hidden");
          } else {
            $clearSearchInput.attr("hidden", "");
          }
        });

        var paramfull = function paramfull(param) {
          if (typeof param[1] === "undefined") {
            return param[0];
          }

          return param[0] + "=" + param[1];
        };

        if (autocompleteHasID) {
          $searchInput.on("keyup", fetchValues);
          $submit.on("click", function () {
            var selectedValues = _.map(_.filter(values, "checked"), "id");

            var params = getParams({
              except: "field" + colId
            });
            selectedValues.forEach(function (value) {
              params.push(["field" + colId, value]);
            });
            window.location = "?" + params.map(function (param) {
              return paramfull(param);
            }).join("&");
          });
        } else {
          $searchInput.on("keypress", function (e) {
            // KeyCode Enter
            if (e.keyCode === 13) {
              e.preventDefault();
              $submit.trigger("click");
            }
          });
          $submit.on("click", function () {
            var params = getParams({
              except: "field" + colId
            });
            params.push(["field" + colId, searchQ()]);
            window.location = "?" + params.map(function (param) {
              return paramfull(param);
            }).join("&");
          });
        }

        $clearSearchInput.on("click", function (e) {
          e.preventDefault();
          $searchInput.val("");
          $clearSearchInput.attr("hidden", "");
          onEmptySearch();
        });
        renderValues();
      });
    };

    return function (context) {
      setupColumnFilters(context);
    };
  }();

  var positionDisclosure = function positionDisclosure(offsetTop, offsetLeft, triggerHeight) {
    var $disclosure = this;
    var left = offsetLeft + "px";
    var top = offsetTop + triggerHeight + "px";
    $disclosure.css({
      left: left,
      top: top
    }); // If the popover is outside the body move it a bit to the left

    if (document.body && document.body.clientWidth && $disclosure.get(0).getBoundingClientRect) {
      var windowOffset = document.body.clientWidth - $disclosure.get(0).getBoundingClientRect().right;

      if (windowOffset < 0) {
        $disclosure.css({
          left: offsetLeft + windowOffset + "px"
        });
      }
    }
  };

  var toggleDisclosure = function toggleDisclosure(e, $trigger, state, permanent) {
    $trigger.attr("aria-expanded", state);
    $trigger.toggleClass("expanded--permanent", state && permanent);
    var expandedLabel = $trigger.data("label-expanded");
    var collapsedLabel = $trigger.data("label-collapsed");

    if (collapsedLabel && expandedLabel) {
      $trigger.html(state ? expandedLabel : collapsedLabel);
    }

    var $disclosure = $trigger.siblings(".expandable").first();
    $disclosure.toggleClass("expanded", state);

    if ($disclosure.hasClass("popover")) {
      var offset = $trigger.offset();
      var top = offset.top;
      var left = offset.left;
      var offsetParent = $trigger.offsetParent();

      if (offsetParent) {
        var offsetParentOffset = offsetParent.offset();
        top = top - offsetParentOffset.top;
        left = left - offsetParentOffset.left;
      }

      positionDisclosure.call($disclosure, top, left, $trigger.outerHeight() + 6);
    }

    $trigger.trigger(state ? "expand" : "collapse", $disclosure); // If this element is within another element that also has a handler, then
    // stop that second handler also doing its action. E.g. for a more-less
    // widget within a table row, do not action both the more-less widget and
    // the opening of a record by clicking on the row

    e.stopPropagation();
  };

  var onDisclosureClick = function onDisclosureClick(e) {
    var $trigger = $(this);
    var currentlyPermanentExpanded = $trigger.hasClass("expanded--permanent");
    toggleDisclosure(e, $trigger, !currentlyPermanentExpanded, true);
  };

  var onDisclosureMouseover = function onDisclosureMouseover(e) {
    var $trigger = $(this);
    var currentlyExpanded = $trigger.attr("aria-expanded") === "true";

    if (!currentlyExpanded) {
      toggleDisclosure(e, $trigger, true, false);
    }
  };

  var onDisclosureMouseout = function onDisclosureMouseout(e) {
    var $trigger = $(this);
    var currentlyExpanded = $trigger.attr("aria-expanded") === "true";
    var currentlyPermanentExpanded = $trigger.hasClass("expanded--permanent");

    if (currentlyExpanded && !currentlyPermanentExpanded) {
      toggleDisclosure(e, $trigger, false, false);
    }
  };

  var setupDisclosureWidgets = function setupDisclosureWidgets(context) {
    $(".trigger[aria-expanded]", context).on("click", onDisclosureClick); // Also show/hide disclosures on hover for widgets with the data-expand-on-hover attribute set to true

    $(".trigger[aria-expanded][data-expand-on-hover=true]", context).on("mouseover", onDisclosureMouseover);
    $(".trigger[aria-expanded][data-expand-on-hover=true]", context).on("mouseout", onDisclosureMouseout);
  };

  var setupSelectWidgets = function () {
    /*
     * A SelectWidget is a custom disclosure widget
     * with multi or single options selectable.
     * SelectWidgets can depend on each other;
     * for instance if Value "1" is selected in Widget "A",
     * Widget "B" might not be displayed.
     */
    var SelectWidget = function SelectWidget(multi) {
      var $selectWidget = this;
      var $widget = this.find(".form-control");
      var $trigger = $widget.find("[aria-expanded]");
      var $current = this.find(".current");
      var $available = this.find(".available");
      var $availableItems = this.find(".available .answer input");
      var $moreInfoButtons = this.find(".available .answer .more-info");
      var $target = this.find("#" + $trigger.attr("aria-controls"));
      var $currentItems = $current.find("[data-list-item]");
      var $answers = this.find(".answer");
      var $fakeInput = null;
      var $search = this.find(".form-control-search");
      var lastFetchParams = null;

      var collapse = function collapse($widget, $trigger, $target) {
        $selectWidget.removeClass("select-widget--open");
        $trigger.attr("aria-expanded", false); // Add a small delay when hiding the select widget, to allow IE to also
        // fire the default actions when selecting a radio button by clicking on
        // its label. When the input is hidden on the click event of the label
        // the input isn't actually being selected.

        setTimeout(function () {
          $search.val("");
          $target.attr("hidden", "");
          $answers.removeAttr("hidden");
        }, 50);
      };

      var updateState = function updateState(no_trigger_change) {
        var $visible = $current.children("[data-list-item]:not([hidden])");
        $current.toggleClass("empty", $visible.length === 0);
        if (!no_trigger_change) $widget.trigger("change");
      };

      var possibleCloseWidget = function possibleCloseWidget(e) {
        var newlyFocussedElement = e.relatedTarget || document.activeElement;

        if (!$selectWidget.find(newlyFocussedElement).length && newlyFocussedElement && !$(newlyFocussedElement).is(".modal, .page") && $selectWidget.get(0).parentNode !== newlyFocussedElement) {
          collapse($widget, $trigger, $target);
        }
      };

      var connectMulti = function connectMulti(update) {
        return function () {
          var $item = $(this);
          var itemId = $item.data("list-item");
          var $associated = $("#" + itemId);
          $associated.unbind("change");
          $associated.on("change", function (e) {
            e.stopPropagation();

            if ($(this).prop("checked")) {
              $item.removeAttr("hidden");
            } else {
              $item.attr("hidden", "");
            }

            update();
          });
          $associated.unbind("keydown");
          $associated.on("keydown", function (e) {
            var key = e.which || e.keyCode;

            switch (key) {
              case 38: // UP

              case 40:
                // DOWN
                var answers = $available.find(".answer:not([hidden])");
                var currentIndex = answers.index($associated.closest(".answer"));
                var nextItem;
                e.preventDefault();

                if (key === 38) {
                  nextItem = answers[currentIndex - 1];
                } else {
                  nextItem = answers[currentIndex + 1];
                }

                if (nextItem) {
                  $(nextItem).find("input").focus();
                }

                break;

              case 13:
                e.preventDefault();
                $(this).trigger("click");
                break;
            }
          });
        };
      };

      var connectSingle = function connectSingle() {
        $currentItems.each(function (_, item) {
          var $item = $(item);
          var itemId = $item.data("list-item");
          var $associated = $("#" + itemId);
          $associated.unbind("click");
          $associated.on("click", function (e) {
            e.stopPropagation();
          });
          $associated.parent().unbind("keypress");
          $associated.parent().on("keypress", function (e) {
            // KeyCode Enter or Spacebar
            if (e.keyCode === 13 || e.keyCode === 32) {
              e.preventDefault();
              $(this).trigger("click");
            }
          });
          $associated.parent().unbind("click");
          $associated.parent().on("click", function (e) {
            e.stopPropagation();
            $currentItems.each(function () {
              $(this).attr("hidden", "");
            });
            $current.toggleClass("empty", false);
            $item.removeAttr("hidden");
            collapse($widget, $trigger, $target);
          });
        });
      };

      var connect = function connect() {
        if (multi) {
          $currentItems.each(connectMulti(updateState));
        } else {
          connectSingle();
        }
      };

      var currentLi = function currentLi(multi, field, value, label, checked, html) {
        if (multi && !value) {
          return $('<li class="none-selected">blank</li>');
        }

        var valueId = value ? field + "_" + value : field + "__blank";
        var className = value ? "" : "current__blank";
        var deleteButton = multi ? '<button type="button" class="close select-widget-value__delete" aria-hidden="true" aria-label="delete" title="delete" tabindex="-1">&times;</button>' : "";
        var $li = $("<li " + (checked ? "" : "hidden") + ' data-list-item="' + valueId + '" class="' + className + '"><span class="widget-value__value">' + "</span>" + deleteButton + "</li>");
        $li.data('list-text', label);
        $li.find('span').html(html);
        return $li;
      };

      var availableLi = function availableLi(multi, field, value, label, checked, html) {
        if (multi && !value) {
          return null;
        }

        var valueId = value ? field + "_" + value : field + "__blank";
        var classNames = value ? "answer" : "answer answer--blank"; // Add space at beginning to keep format consistent with that in template

        var detailsButton = ' <span class="details">' + '<button type="button" class="more-info" data-record-id="' + value + '" aria-describedby="' + valueId + '_label" aria-haspopup="listbox">' + "Details" + "</button>" + "</span>";
        var $span = $('<span role="option"></span>');
        $span.data('list-text', label);
        $span.data('list-id', value);
        $span.html(html);
        var $li = $('<li class="' + classNames + '">' + '<span class="control">' + '<label id="' + valueId + '_label" for="' + valueId + '">' + '<input id="' + valueId + '" type="' + (multi ? "checkbox" : "radio") + '" name="' + field + '" ' + (checked ? "checked" : "") + ' value="' + (value || "") + '" class="' + (multi ? "" : "visually-hidden") + '" aria-labelledby="' + valueId + '_label"> ' + // Add space to keep spacing consistent with templates
        "</label>" + "</span>" + (value ? detailsButton : "") + "</li>");
        $li.find('label').append($span);
        return $li;
      }; // Give each AJAX load its own ID. If a higher ID has started by the time
      // we get the results, then cancel the current process to prevent
      // duplicate items being added to the dropdown


      var loadCounter = 0;

      var updateJson = function updateJson(url, typeahead) {
        loadCounter++;
        var myLoad = loadCounter; // ID of this process

        $available.find(".spinner").removeAttr("hidden");
        var currentValues = $available.find("input:checked").map(function () {
          return parseInt($(this).val());
        }).get(); // Remove existing items if needed, now that we have found out which ones
        // are selected

        if (!typeahead) $available.find(".answer").remove();
        var field = $selectWidget.data("field"); // If we cancel this particular loop, then we don't want to remove the
        // spinner if another one has since started running

        var hideSpinner = true;
        $.getJSON(url, function (data) {
          if (data.error === 0) {
            if (myLoad != loadCounter) {
              // A new one has started running
              hideSpinner = false; // Don't remove the spinner on completion

              return;
            }

            if (typeahead) {
              // Need to keep currently selected item
              $currentItems.filter(':hidden').remove();
            } else {
              $currentItems.remove();
            }

            var checked = currentValues.includes(NaN);

            if (multi) {
              $search.parent().prevAll(".none-selected").remove(); // Prevent duplicate blank entries

              $search.parent().before(currentLi(multi, field, null, "blank", checked));
              $available.append(availableLi(multi, field, null, "blank", checked));
            }

            $.each(data.records, function (recordIndex, record) {
              var checked = currentValues.includes(record.id);

              if (!typeahead || typeahead && !checked) {
                $search.parent().before(currentLi(multi, field, record.id, record.label, checked, record.html)).before(' '); // Ensure space between elements

                $available.append(availableLi(multi, field, record.id, record.label, checked, record.html));
              }
            });
            $currentItems = $current.find("[data-list-item]");
            $available = $selectWidget.find(".available");
            $availableItems = $selectWidget.find(".available .answer input");
            $moreInfoButtons = $selectWidget.find(".available .answer .more-info");
            $answers = $selectWidget.find(".answer");
            updateState();
            connect();
            $availableItems.on("blur", possibleCloseWidget);
            $moreInfoButtons.on("blur", possibleCloseWidget);
          } else {
            var errorMessage = data.error === 1 ? data.message : "Oops! Something went wrong.";
            var errorLi = $('<li class="answer answer--blank alert alert-danger"><span class="control"><label>' + errorMessage + "</label></span></li>");
            $available.append(errorLi);
          }
        }).fail(function (jqXHR, textStatus, textError) {
          var errorMessage = "Oops! Something went wrong.";
          Linkspace.error("Failed to make request to " + filterEndpoint + ": " + textStatus + ": " + textError);
          var errorLi = $('<li class="answer answer--blank alert alert-danger"><span class="control"><label>' + errorMessage + "</label></span></li>");
          $available.append(errorLi);
        }).always(function () {
          if (hideSpinner) {
            $available.find(".spinner").attr("hidden", "");
          }
        });
      };

      var fetchOptions = function fetchOptions() {
        var field = $selectWidget.data("field");
        var multi = $selectWidget.hasClass("multi");
        var filterEndpoint = $selectWidget.data("filter-endpoint");
        var filterFields = $selectWidget.data("filter-fields");
        var submissionToken = $selectWidget.data("submission-token");

        if (!$.isArray(filterFields)) {
          Linkspace.error("Invalid data-filter-fields found. It should be a proper JSON array of fields.");
        } // Collect values of linked fields


        var values = ["submission-token=" + submissionToken];
        $.each(filterFields, function (_, field) {
          $("input[name=" + field + "]").each(function (_, input) {
            var $input = $(input);

            switch ($input.attr("type")) {
              case "text":
                values.push(field + "=" + $input.val());
                break;

              case "radio":
                if (input.checked) {
                  values.push(field + "=" + $input.val());
                }

                break;

              case "checkbox":
                if (input.checked) {
                  values.push(field + "=" + $input.val());
                }

                break;

              case "hidden":
                // Tree values stored as hidden field
                values.push(field + "=" + $input.val());
                break;
            }
          });
        }); // Bail out if the options haven't changed

        var fetchParams = values.join("&");

        if (lastFetchParams === fetchParams) {
          return;
        }

        lastFetchParams = null;
        updateJson(filterEndpoint + "?" + fetchParams);
        lastFetchParams = fetchParams;
      };

      var expand = function expand($widget, $trigger, $target) {
        if ($trigger.attr("aria-expanded") === "true") {
          return;
        }

        $selectWidget.addClass("select-widget--open");
        $trigger.attr("aria-expanded", true);

        if ($selectWidget.data("filter-endpoint") && $selectWidget.data("filter-endpoint").length) {
          fetchOptions();
        }

        var widgetTop = $widget.offset().top;
        var widgetBottom = widgetTop + $widget.outerHeight();
        var viewportTop = $(window).scrollTop();
        var viewportBottom = viewportTop + $(window).height() - 60;
        var minimumRequiredSpace = 200;
        var fitsBelow = widgetBottom + minimumRequiredSpace < viewportBottom;
        var fitsAbove = widgetTop - minimumRequiredSpace > viewportTop;
        var expandAtTop = fitsAbove && !fitsBelow;
        $target.toggleClass("available--top", expandAtTop);
        $target.removeAttr("hidden");

        if ($search.get(0) !== document.activeElement) {
          $search.focus();
        }
      };

      updateState(true);
      connect();
      $widget.unbind("click");
      $widget.on("click", function () {
        if ($trigger.attr("aria-expanded") === "true") {
          collapse($widget, $trigger, $target);
        } else {
          expand($widget, $trigger, $target);
        }
      });
      $search.unbind("blur");
      $search.on("blur", possibleCloseWidget);
      $availableItems.unbind("blur");
      $availableItems.on("blur", possibleCloseWidget);
      $moreInfoButtons.unbind("blur");
      $moreInfoButtons.on("blur", possibleCloseWidget);
      $(document).on("click", function (e) {
        var clickedOutside = !this.is(e.target) && this.has(e.target).length === 0;
        var clickedInDialog = $(e.target).closest(".modal").length !== 0;

        if (clickedOutside && !clickedInDialog) {
          collapse($widget, $trigger, $target);
        }
      }.bind(this));
      $(document).keyup(function (e) {
        if (e.keyCode == 27) {
          collapse($widget, $trigger, $target);
        }
      });

      var expandWidgetHandler = function expandWidgetHandler(e) {
        e.stopPropagation();
        expand($widget, $trigger, $target);
      };

      $widget.delegate(".select-widget-value__delete", "click", function (e) {
        e.preventDefault();
        e.stopPropagation(); // Uncheck checkbox

        var checkboxId = e.target.parentElement.getAttribute("data-list-item");
        var checkbox = document.querySelector("#" + checkboxId);
        checkbox.checked = false;
        $(checkbox).trigger("change");
      });
      $search.unbind("focus", expandWidgetHandler);
      $search.on("focus", expandWidgetHandler);
      $search.unbind("keydown");
      $search.on("keydown", function (e) {
        var key = e.which || e.keyCode;

        switch (key) {
          case 38: // UP

          case 40:
            // DOWN
            var items = $available.find(".answer:not([hidden]) input");
            var nextItem;
            e.preventDefault();

            if (key === 38) {
              nextItem = items[items.length - 1];
            } else {
              nextItem = items[0];
            }

            if (nextItem) {
              $(nextItem).focus();
            }

            break;

          case 13:
            // ENTER
            e.preventDefault(); // Select the first (visible) item

            var firstItem = $available.find(".answer:not([hidden]) input").get(0);

            if (firstItem) {
              $(firstItem).parent().trigger("click");
            }

            break;
        }
      });
      $search.unbind("keyup");
      var timeout;
      $search.on("keyup", function () {
        var searchValue = $(this).val().toLowerCase();
        $fakeInput = $fakeInput || $("<span>").addClass("form-control-search").css("white-space", "nowrap");
        $fakeInput.text(searchValue);
        $search.css("width", $fakeInput.insertAfter($search).width() + 70);
        $fakeInput.detach();

        if ($selectWidget.data("value-selector") == "typeahead") {
          var url = "/".concat($selectWidget.data("layout-id"), "/match/layout/").concat($selectWidget.data("typeahead-id")); // Debounce the user input, only execute after 200ms if another one
          // hasn't started

          clearTimeout(timeout);
          $available.find(".spinner").removeAttr("hidden");
          timeout = setTimeout(function () {
            $available.find(".answer").not('.answer--blank').each(function () {
              var $answer = $(this);

              if (!$answer.find('input:checked').length) {
                $answer.remove();
              }
            });
            updateJson(url + '?noempty=1&q=' + searchValue, true);
          }, 200);
        } else {
          // hide the answers that do not contain the searchvalue
          var anyHits = false;
          $.each($answers, function () {
            var labelValue = $(this).find("label")[0].innerHTML.toLowerCase();

            if (labelValue.indexOf(searchValue) === -1) {
              $(this).attr("hidden", "");
            } else {
              anyHits = true;
              $(this).removeAttr("hidden", "");
            }
          });

          if (anyHits) {
            $available.find(".has-noresults").attr("hidden", "");
          } else {
            $available.find(".has-noresults").removeAttr("hidden", "");
          }
        }
      });
      $search.unbind("click");
      $search.on("click", function (e) {
        // Prevent bubbling the click event to the $widget (which expands/collapses the widget on click).
        e.stopPropagation();
      });
    };

    var init = function init(context) {
      var $nodes = $(".select-widget", context);
      $nodes.each(function () {
        var multi = $(this).hasClass("multi");
        SelectWidget.call($(this), multi);
      });
    };

    return function (context) {
      init(context);
    };
  }();

  // General function to format date as per backend
  var format_date = function format_date(date) {
    if (!date) return undefined;
    return {
      year: date.getFullYear(),
      month: date.getMonth() + 1,
      // JS returns 0-11, Perl 1-12
      day: date.getDate(),
      hour: 0,
      minute: 0,
      second: 0,
      //yday: > $value->doy, // TODO
      epoch: date.getTime() / 1000
    };
  }; // get the value from a field, depending on its type


  var getFieldValues = function getFieldValues($depends, filtered, for_code) {
    var type = $depends.data("column-type"); // If a field is not shown then treat it as a blank value (e.g. if fields
    // are in a hierarchy and the top one is not shown, or if the user does
    // not have write access to the field).
    // At the moment do not do this for calc fields, as these are not currently
    // shown and therefore will always return blank. This may need to be
    // updated in the future in order to do something similar as normal fields
    // (returning blank if they themselves would not be shown under display
    // conditions)

    if ($depends.length == 0 || $depends.css("display") == "none") {
      if (type != "calc") {
        return [""];
      }
    }

    var values = [];
    var $visible;
    var $f;

    if (type === "enum" || type === "curval") {
      if (filtered) {
        // Field is type "filval". Therefore the values are any visible value in
        // the associated filtered drop-down
        $visible = $depends.find(".select-widget .available .answer");
        $visible.each(function () {
          var item = $(this).find('[role="option"]');
          values.push(item);
        });
      } else {
        $visible = $depends.find(".select-widget .current [data-list-item]:not([hidden])");
        $visible.each(function () {
          var item = $(this).hasClass("current__blank") ? undefined : $(this);
          values.push(item);
        });
      }

      if (for_code) {
        if ($depends.data('is-multivalue')) {
          // multivalue
          var vals = $.map(values, function (item) {
            return {
              id: item.data("list-id"),
              value: item.data("list-text")
            };
          });
          var plain = $.map(vals, function (item) {
            return item.value;
          });
          return {
            text: plain.join(', '),
            values: vals
          };
        } else {
          // single value
          if (values.length && values[0]) {
            return values[0].data("list-text");
          } else {
            return undefined;
          }
        }
      } else {
        values = $.map(values, function (item) {
          if (item) {
            return item.data("list-text");
          } else {
            return "";
          }
        });
      }
    } else if (type === "person") {
      values = [$depends.find("option:selected").text()];
    } else if (type === "tree") {
      // get the hidden fields of the control - their textual value is located in a dat field
      $depends.find(".selected-tree-value").each(function () {
        values.push($(this).data("text-value"));
      });
    } else if (type === "daterange") {
      $f = $depends.find(".form-control"); // Dateranges from the form are in pairs. Convert to single objects:

      var dateranges = [];
      var from_date;
      $f.each(function (index) {
        if (index % 2 == 0) {
          // from date
          from_date = $(this);
        } else {
          // to date
          dateranges.push({
            from: from_date,
            to: $(this)
          });
        }
      });

      if (for_code) {
        var codevals = dateranges.map(function (dr) {
          var from = dr.from.datepicker("getDate");
          var to = dr.to.datepicker("getDate");

          if (!from || !to) {
            return undefined;
          }

          return {
            from: format_date(from),
            to: format_date(to),
            value: dr.from.val() + ' to ' + dr.to.val()
          };
        });

        if ($depends.data('is-multivalue')) {
          return codevals;
        } else {
          return codevals[0];
        }
      } else {
        values = dateranges.map(function (dr) {
          return dr.from.val() + ' to ' + dr.to.val();
        });
      }
    } else if (type === "date") {
      if ($depends.data('is-multivalue')) {
        values = $depends.find(".form-control").map(function () {
          var $df = $(this);
          return for_code ? format_date($df.datepicker("getDate")) : $df.val();
        }).get();

        if (for_code) {
          return values;
        }
      } else {
        var $df = $depends.find(".form-control");

        if (for_code) {
          return format_date($df.datepicker("getDate"));
        } else {
          values = [$df.val()];
        }
      }
    } else {
      // Can't use map as an undefined return value is skipped
      values = [];
      $depends.find(".form-control").each(function () {
        var $df = $(this);
        values.push($df.val().length ? $df.val() : undefined);
      }); // Provide consistency with backend: single value is returned as scalar

      if (for_code && !$depends.data('is-multivalue')) {
        values = values.shift();
      }
    } // A multi-select field with no values selected should be the same as a
    // single-select with no values. Ensure that both are returned as a single
    // empty string value. This is important for display_condition testing, so
    // that at least one value is tested, even if it's empty


    if (Array.isArray(values) && values.length == 0) {
      values = [""];
    }

    return values;
  };

  var guid = function guid() {
    var S4 = function S4() {
      return ((1 + Math.random()) * 0x10000 | 0).toString(16).substring(1);
    };

    return S4() + S4() + "-" + S4() + "-" + S4() + "-" + S4() + "-" + S4() + S4() + S4();
  };

  var setupCurvalModal = function () {
    var curvalModalValidationSucceeded = function curvalModalValidationSucceeded(form, values, context) {
      var form_data = form.serialize();
      var modal_field_ids = form.data("modal-field-ids");
      var col_id = form.data("curval-id");
      var instance_name = form.data("instance-name"); //var parent_current_id = form.data("parent-current-id");

      var guid$1 = form.data("guid");
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
        var links = $("<td>\n        <a class=\"curval-modal\" style=\"cursor:pointer\" data-layout-id=\"".concat(col_id, "\" data-instance-name=\"").concat(instance_name, "\">edit</a> | <a class=\"curval_remove\" style=\"cursor:pointer\">remove</a>\n      </td>"), context);
        row_cells.append(links.append(hidden_input));

        if (guid$1) {
          var hidden = $('input[data-guid="' + guid$1 + '"]', context).val(form_data);
          hidden.closest(".curval_item").replaceWith(row_cells);
        } else {
          $("#curval_list_".concat(col_id), context).find("tbody").prepend(row_cells);
        }
      } else {
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
        guid$1 = guid();
        var id = "field".concat(col_id, "_").concat(guid$1);
        var deleteButton = multi ? '<button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete" title="delete" tabindex="-1">&times;</button>' : "";
        $search.before("<li data-list-item=\"".concat(id, "\">").concat(textValue).concat(deleteButton, "</li>")).before(' '); // Ensure space between elements in widget

        var inputType = multi ? "checkbox" : "radio";
        $answersList.append("<li class=\"answer\">\n        <span class=\"control\">\n            <label id=\"".concat(id, "_label\" for=\"").concat(id, "\">\n                <input id=\"").concat(id, "\" name=\"field").concat(col_id, "\" type=\"").concat(inputType, "\" value=\"").concat(form_data, "\" class=\"").concat(multi ? "" : "visually-hidden", "\" checked aria-labelledby=\"").concat(id, "_label\">\n                <span>").concat(textValue, "</span>\n            </label>\n        </span>\n        <span class=\"details\">\n            <a class=\"curval_remove\" style=\"cursor:pointer\">remove</a>\n        </span>\n      </li>"));
        /* Reinitialize widget */

        setupSelectWidgets($formGroup);
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
        var instance_name = $(e.target).data("instance-name"); //var parent_current_id = $(e.target).data("parent-current-id");

        var current_id = $(e.target).data("current-id");
        var hidden = $(e.target).closest(".curval_item").find("input[name=field".concat(layout_id, "]"));
        var form_data = hidden.val();
        var mode = hidden.length ? "edit" : "add";
        var guid$1;

        if (mode === "edit") {
          guid$1 = hidden.data("guid");

          if (!guid$1) {
            guid$1 = guid();
            hidden.attr("data-guid", guid$1);
          }
        }

        var m = $("#curval_modal", context);
        m.find(".modal-body").text("Loading...");
        var url = current_id ? "/record/".concat(current_id) : "/".concat(instance_name, "/record/");
        m.find(".modal-body").load("".concat(url, "?include_draft&modal=").concat(layout_id, "&").concat(form_data), function () {
          if (mode === "edit") {
            m.find("form").data("guid", guid$1);
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
        $.post(form.attr("action") + "?validate&include_draft&source=" + form.data("curval-id"), form_data, function (data) {
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
        if (confirm("Are you sure want to permanently remove this item?")) {
          $(this).closest(".curval_item").remove();
        } else {
          e.preventDefault();
        }
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
  }();

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
  }();

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
        var $modal = $(this); // Remove existing body first so that the previously-viewed help text
        // doesn't show whilst the current one loads

        var $modal_body = $modal.find('.modal-body').html('');
        $.ajax(loadurl, {
          timeout: 5000,
          success: function success(data) {
            $modal_body.html(data);
          },
          error: function error() {
            alert("Failed to load help text");
            $modal.modal('hide');
          }
        });
      });
      $("#helptext_modal_close").on('click', function (e) {
        $('#helptext_modal').modal('hide');
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
  }();

  var setupFileUpload = function () {
    var setupFileUpload = function setupFileUpload(context) {
      var $nodes = $(".fileupload", context);
      $nodes.each(function () {
        var $el = $(this);
        var $ul = $el.find("ul");
        var url = $el.data("fileupload-url");
        var field = $el.data("field");
        var $progressBarContainer = $el.find(".progress-bar__container");
        var $progressBarProgress = $el.find(".progress-bar__progress");
        var $progressBarPercentage = $el.find(".progress-bar__percentage");
        $el.fileupload({
          dataType: "json",
          url: url,
          paramName: "file",
          submit: function submit() {
            $progressBarContainer.css("display", "block");
            $progressBarPercentage.html("0%");
            $progressBarProgress.css("width", "0%");
            $progressBarProgress.removeClass('progress-bar__fail');
          },
          progress: function progress(e, data) {
            if (!$el.data("multivalue")) {
              var $uploadProgression = Math.round(data.loaded / data.total * 10000) / 100 + "%";
              $progressBarPercentage.html($uploadProgression);
              $progressBarProgress.css("width", $uploadProgression);
            }
          },
          progressall: function progressall(e, data) {
            if ($el.data("multivalue")) {
              var $uploadProgression = Math.round(data.loaded / data.total * 10000) / 100 + "%";
              $progressBarPercentage.html($uploadProgression);
              $progressBarProgress.css("width", $uploadProgression);
            }
          },
          done: function done(e, data) {
            if (!$el.data("multivalue")) {
              $ul.empty();
            }

            var fileId = data.result.url.split("/").pop();
            var fileName = data.files[0].name;
            var $li = $('<li class="help-block"><input type="checkbox" name="' + field + '" value="' + fileId + '" aria-label="' + fileName + '" checked>Include file. Current file name: <a href="/file/' + fileId + '">' + fileName + "</a>.</li>");
            $ul.append($li);
          },
          fail: function fail(e, data) {
            var ret = data.jqXHR.responseJSON;
            $progressBarProgress.css("width", "100%");
            $progressBarProgress.addClass('progress-bar__fail');

            if (ret.message) {
              $progressBarPercentage.html("Error: " + ret.message);
            } else {
              $progressBarPercentage.html("An unexpected error occurred");
            }
          }
        });
      });
    };

    return function (context) {
      setupFileUpload(context);
    };
  }();

  var setupFirstInputFocus = function () {
    var setupFirstInputFocus = function setupFirstInputFocus(context) {
      $(".edit-form *:input[type!=hidden]:first", context).focus();
    };

    return function (context) {
      setupFirstInputFocus(context);
    };
  }();

  var setupGlobeById = function () {
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
  }();

  var setupGlobeByClass = function () {
    var initGlobe = function initGlobe(container) {
      Plotly.setPlotConfig({
        locale: "en-GB"
      });
      var globe_data = JSON.parse(base64.decode(container.data("globe-data")));
      var data = globe_data.data;
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
        topojsonURL: container.data("topojsonurl")
      };
      Plotly.newPlot(container.get(0), data, layout, options).then(function (gd) {
        // Set up handler to show records of country when country is clicked
        gd.on("plotly_click", function (d) {
          // Prevent click event when map is dragged
          if (d.event.defaultPrevented) return;
          var pt = (d.points || [])[0]; // Point clicked

          var params = globe_data.params; // Construct filter to only show country clicked.
          // XXX This will filter only when all globe fields of the record
          // are equal to the country. This should be an "OR" condition
          // instead

          var filter = params.globe_fields.map(function (field) {
            return field + "=" + pt.location;
          }).join("&");
          var url = "/" + params.layout_identifier + "/data?viewtype=table&view=" + params.view_id + "&" + filter;

          if (params.default_view_limit_extra_id) {
            url = url + "&extra=" + params.default_view_limit_extra_id;
          }

          location.href = url;
        });
      });
    };

    return function (context) {
      initGlobe(context);
    };
  }();

  var setupHtmlEditor = function () {
    var handleHtmlEditorFileUpload = function handleHtmlEditorFileUpload(file, el) {
      if (file.type.includes("image")) {
        var data = new FormData();
        data.append("file", file);
        data.append("csrf_token", $("body").data("csrf-token"));
        $.ajax({
          url: "/file?ajax&is_independent",
          type: "POST",
          contentType: false,
          cache: false,
          processData: false,
          dataType: "JSON",
          data: data,
          success: function success(response) {
            if (response.is_ok) {
              $(el).summernote("editor.insertImage", response.url);
            } else {
              Linkspace.debug(response.error);
            }
          }
        }).fail(function (e) {
          Linkspace.debug(e);
        });
      } else {
        Linkspace.debug("The type of file uploaded was not an image");
      }
    };

    var setupHtmlEditor = function setupHtmlEditor(context) {
      // Legacy editor - may be needed for IE8 support in the future

      /*
      tinymce.init({
          selector: "textarea",
          width : "800",
          height : "400",
          plugins : "table",
          theme_advanced_buttons1 : "bold, italic, underline, strikethrough, justifyleft, justifycenter, justifyright, bullist, numlist, outdent, i
          theme_advanced_buttons2 : "tablecontrols",
          theme_advanced_buttons3 : ""
      });
      */
      if (!$.summernote) {
        return;
      }

      $(".summernote", context).summernote({
        dialogsInBody: true,
        height: 400,
        callbacks: {
          // Load initial content
          onInit: function onInit() {
            var $sum_div = $(this);
            var $sum_input = $sum_div.siblings("input[type=hidden].summernote_content");
            $(this).summernote("code", $sum_input.val());
          },
          onImageUpload: function onImageUpload(files) {
            for (var i = 0; i < files.length; i++) {
              handleHtmlEditorFileUpload(files[i], this);
            }
          },
          onChange: function onChange(contents) {
            var $sum_div = $(this).closest(".summernote"); // Ensure submitted content is empty string if blank content
            // (easier checking for blank values)

            if ($sum_div.summernote("isEmpty")) {
              contents = "";
            }

            var $sum_input = $sum_div.siblings("input[type=hidden].summernote_content");
            $sum_input.val(contents);
          }
        }
      });
    };

    return function (context) {
      setupHtmlEditor(context);
    };
  }();

  var setupJStreeButtons = function () {
    var setupJStreeButtons = function setupJStreeButtons($treeContainer) {
      // Set up expand/collapse buttons located above widget
      $treeContainer.prevAll('.jstree-expand-all').on('click', function () {
        $treeContainer.jstree(true).open_all();
      });
      $treeContainer.prevAll('.jstree-collapse-all').on('click', function () {
        $treeContainer.jstree(true).close_all();
      });
      $treeContainer.prevAll('.jstree-reload').on('click', function () {
        $treeContainer.jstree(true).refresh();
      });
    };

    return function ($treeContainer) {
      setupJStreeButtons($treeContainer);
    };
  }();

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
          worker: false,
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
      setupJStreeButtons(treeEl);
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
      var filters = JSON.parse(base64.decode(builderData.filters));
      if (!filters.length) return;
      conditionsBuilder.queryBuilder({
        filters: filters,
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

    var setupNotify = function setupNotify(context) {
      $("#notify_on_selection", context).on("change", function () {
        if ($(this).prop("checked")) {
          $("#notify-options", context).show();
        } else {
          $("#notify-options", context).hide();
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
      setupNotify(context);
    };
  }();

  var setupLessMoreWidgets = function () {
    var uuid = function uuid() {
      return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
        var r = Math.random() * 16 | 0,
            v = c == "x" ? r : r & 0x3 | 0x8;
        return v.toString(16);
      });
    }; // Traverse up through the tree and find the parent element that is hidden


    var parentHidden = function parentHidden($elem) {
      if ($elem.css("display") == "none") {
        return $elem;
      }

      var $parent = $elem.parent();

      if (!$parent || !$parent.length) {
        return undefined;
      }

      return parentHidden($parent);
    }; // We previously used a plugin for this
    // (https://github.com/dreamerslab/jquery.actual) but its performance was slow
    // when a page had many more-less divs


    var getActualHeight = function getActualHeight($elem) {
      if ($elem.attr("data-actual-height")) {
        // cached heights from previous runs
        return $elem.attr("data-actual-height");
      }

      if ($elem.height()) {
        // Assume element is visible
        return $elem.height();
      } // The reason this element is visible could be because of a parent element


      var $parent = parentHidden($elem);

      if (!$parent) {
        return;
      } // Add a unique identifier to each more-less class, before cloning. Once we
      // measure the height on the cloned elements, we can apply the height as a
      // data value to its real equivalent element using this unique class.


      $parent.find(".more-less").each(function () {
        var $e = $(this);
        $e.addClass("more-less-id-" + uuid());
      }); // Clone the element and show it to find out its height

      var $clone = $parent.clone().attr("id", false).css({
        visibility: "hidden",
        display: "block",
        position: "absolute"
      });
      $("body").append($clone); // The cloned element could contain many other hidden more-less divs, so do
      // them all at the same time to improve performance

      $clone.find(".more-less").each(function () {
        var $ml = $(this);
        var classList = $ml.attr("class").split(/\s+/);
        $.each(classList, function (index, item) {
          if (item.indexOf("more-less-id") >= 0) {
            var $toset = $parent.find("." + item); // Can't use data() as it can't be re-read

            $toset.attr("data-actual-height", $ml.height());
          }
        });
      });
      $clone.remove();
      return $elem.attr("data-actual-height");
    };

    var setupLessMoreWidgets = function setupLessMoreWidgets(context) {
      var MAX_HEIGHT = 100;

      var convert = function convert() {
        var $ml = $(this);
        var column = $ml.data("column");
        var content = $ml.html();
        $ml.removeClass("transparent"); // Element may be hidden (e.g. when rendering edit fields on record page).

        if (getActualHeight($ml) < MAX_HEIGHT) {
          return;
        }

        $ml.addClass("clipped");
        var $expandable = $("<div/>", {
          "class": "expandable popover column-content",
          html: content
        });
        var toggleLabel = "Show " + column + " &rarr;";
        var $expandToggle = $("<button/>", {
          "class": "btn btn-xs btn-primary trigger",
          html: toggleLabel,
          type: "button",
          "aria-expanded": false,
          "data-expand-on-hover": true,
          "data-label-expanded": "Hide " + column,
          "data-label-collapsed": toggleLabel
        });
        $expandToggle.on("toggle", function (e, state) {
          var windowWidth = $(window).width();
          var leftOffset = $expandable.offset().left;
          var minWidth = 400;
          var colWidth = $ml.width();
          var newWidth = colWidth > minWidth ? colWidth : minWidth;

          if (state === "expanded") {
            $expandable.css("width", newWidth + "px");

            if (leftOffset + newWidth + 20 < windowWidth) {
              return;
            }

            var overflow = windowWidth - (leftOffset + newWidth + 20);
            $expandable.css("left", leftOffset + overflow + "px");
          }
        });
        $ml.empty().append($expandToggle).append($expandable);
        setupDisclosureWidgets($ml); // Process any more-less divs within this. These won't be done by the
        // original find, as the original ones will have been obliterated by
        // the more-less process

        $expandable.find(".more-less").each(convert);
      };

      var $widgets = $(".more-less", context);
      $widgets.each(convert);
    };

    return function (context) {
      setupLessMoreWidgets(context);
    };
  }();

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
  }();

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
  }();

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
  }();

  var ConfigPage = function ConfigPage() {
    setupHtmlEditor();
  };

  var setupOtherUserViews = function () {
    var setupOtherUserViews = function setupOtherUserViews() {
      var layout_identifier = $("body").data("layout-identifier");
      var url = layout_identifier ? "/" + layout_identifier + "/match/user/" : "/match/user/";
      $("#views_other_user_typeahead").typeahead({
        delay: 500,
        matcher: function matcher() {
          return true;
        },
        sorter: function sorter(items) {
          return items;
        },
        afterSelect: function afterSelect(selected) {
          $("#views_other_user_id").val(selected.id);
        },
        source: function source(query, process) {
          return $.ajax({
            type: "GET",
            url: url,
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
    };

    return function (context) {
      setupOtherUserViews();
    };
  }();

  var DataCalendarPage = function DataCalendarPage() {
    setupOtherUserViews();
  };

  var DataGlobePage = function DataGlobePage() {
    $(".globe").each(function () {
      setupGlobeByClass($(this));
    });
    setupOtherUserViews();
  };

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
      // jqplot does not work in IE8 unless in document.ready
      $(document).ready(function () {
        initGraph(context);
      });
    };
  }();

  var DataGraphPage = function DataGraphPage(context) {
    setupOtherUserViews();
    setupGraph(context);
  };

  var setupHoverableTable = function () {
    var setupHoverableTable = function setupHoverableTable(context) {
      $(".table tr[data-href]", context).on("click", function () {
        window.location = $(this).data("href");
      });
    };

    return function (context) {
      setupHoverableTable(context);
    };
  }();

  var DataTablePage = function DataTablePage() {
    setupHoverableTable();
    setupOtherUserViews();
    $("#modal_sendemail").on("show.bs.modal", function (event) {
      var button = $(event.relatedTarget);
      var peopcol_id = button.data("peopcol_id");
      $("#modal_sendemail_peopcol_id").val(peopcol_id);
    });
    $("#data-table").floatThead({
      floatContainerCss: {},
      zIndex: function zIndex() {
        return 999;
      },
      ariaLabel: function ariaLabel($table, $headerCell) {
        return $headerCell.data("thlabel");
      }
    });

    if (!FontDetect.isFontLoaded("14px/1 FontAwesome")) {
      $(".use-icon-font").hide();
      $(".use-icon-png").show();
    }

    $("#rows_per_page").on("change", function () {
      this.form.submit();
    });
  };

  var setupTippy = function () {
    var setupTippy = function setupTippy(context) {
      var tippyContext = context || document;
      tippy(tippyContext.querySelectorAll(".vis-foreground"), {
        target: ".timeline-tippy",
        theme: "light",
        onShown: function onShown() {
          $(".moreinfo", context).off("click").on("click", function (e) {
            var target = $(e.target);
            var record_id = target.data("record-id");
            var m = $("#readmore_modal");
            m.find(".modal-body").text("Loading...");
            m.find(".modal-body").load("/record_body/" + record_id);
            m.modal();
          });
        }
      });
    };

    return function (context) {
      setupTippy(context);
    };
  }();

  /**
   * This function takes a color (hex) as the argument, calculates the color’s HSP value, and uses that
   * to determine whether the color is light or dark.
   * Source: https://awik.io/determine-color-bright-dark-using-javascript/
   *
   * @param {string} color
   * @returns {string}
   */
  function lightOrDark(color) {
    // Convert it to HEX: http://gist.github.com/983661
    var hexColor = +("0x" + color.slice(1).replace(color.length < 5 && /./g, "$&$&"));
    var r = hexColor >> 16;
    var g = hexColor >> 8 & 255;
    var b = hexColor & 255; // HSP (Perceived brightness) equation from http://alienryderflex.com/hsp.html

    var hsp = Math.sqrt(0.299 * (r * r) + 0.587 * (g * g) + 0.114 * (b * b)); // Using the HSP value, determine whether the color is light or dark.
    // The source link suggests 127.5, but that seems a bit too low.

    if (hsp > 150) {
      return "light";
    }

    return "dark";
  }
  /**
   * this function retrieves the css value of a property in pixels from a supplied html node, as an integer
   *
   * @param {*} node
   * @param {string} property
   * @returns {number}
   */


  function getCssPxValue(node) {
    var property = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 'height';

    if (!node || !node.length) {
      return 0;
    }

    try {
      var value = node.css(property);
      return value ? parseFloat(parseFloat(value.replace('px')).toFixed(4)) : 0;
    } catch (e) {
      console.error('fatal error', e);
      return 0;
    }
  }
  /**
   * This function finds and returns the label belonging to a .vis-group
   *
   * @param {number} groupTop
   * @returns {null|{node: *|null, text: string}}
   */


  function getVisGroupLabelNode(groupTop) {
    var labels = $(".vis-label:visible");
    var label = null;
    labels.each(function () {
      var top = $(this).offset().top;
      top = top === 0 ? getCssTransformCoordinates($(this)).y : top;

      if (Math.floor(top) === groupTop) {
        label = $(this);
      }
    });
    return !label ? null : {
      node: label,
      text: label.find(".vis-inner").first().html() || ""
    };
  }
  /**
   * This function uses the CSS transform value of a VisJS object to determine the X and/or Y coordinate offset of
   * @param obj
   * @returns {{x: number, y: number}}
   */


  function getCssTransformCoordinates(obj) {
    var transformMatrix = obj.css("-webkit-transform") || obj.css("-moz-transform") || obj.css("-ms-transform") || obj.css("-o-transform") || obj.css("transform");
    var matrix = transformMatrix.replace(/[^0-9\-.,]/g, '').split(',');
    var x = matrix[12] || matrix[4]; //translate x

    var y = matrix[13] || matrix[5]; //translate y

    return {
      x: parseFloat(x),
      y: parseFloat(y)
    };
  }
  /**
   * finds all .vis-item nodes under a .vis-group and groups them per row based on the
   * 'top' CSS propery of the item. These items are positioned absolute.
   *
   * @param {*} group
   * @returns {*}
   */


  function getVisItemRowsInGroup(group) {
    var itemRows = [];
    var itemCache = {};
    var topCache = [];
    var items = group.find(".vis-item:visible");
    items.each(function () {
      var top = getCssPxValue($(this), "top");
      var coordinates = getCssTransformCoordinates($(this));
      top = top === 0 ? coordinates.y : top;

      if ($.inArray(top, topCache) === -1) {
        topCache.push(top);
      }

      if (!itemCache[top]) {
        itemCache[top] = [];
      }

      itemCache[top].push({
        node: $(this),
        label: $(this).find(".timeline-tippy").html().trim(),
        width: getCssPxValue($(this), 'width'),
        x: coordinates.x,
        y: coordinates.y,
        top: top,
        textColor: $(this).css('color') ? $(this).css('color') : false,
        backgroundColor: $(this).css('background-color')
      });
    });
    topCache.sort(function (a, b) {
      return a > b ? 1 : -1;
    });
    $.each(topCache, function (index, top) {
      itemRows.push(itemCache[top]);
    });
    return itemRows;
  }
  /**
   * this function retrieves a .vis-group thats in the foreground scope, and extracts the
   * required parameters. It matches a .vis-group in the background scope based on its
   * height, and a label based on its top offset. Items inside the group are collected
   * and sorted by row.
   *
   * @param {*} group
   * @returns {{backgroundGroup: *, node, itemRows: *, top, label: *, height: (number|number)}}
   */


  function getVisGroup(group) {
    var top = Math.floor(group.offset().top);
    var height = getCssPxValue(group, "height");
    var itemRows = getVisItemRowsInGroup(group);
    top = top === 0 ? getCssTransformCoordinates(group).y : top;
    return {
      node: group,
      top: top,
      height: height,
      label: getVisGroupLabelNode(top),
      itemRows: itemRows
    };
  }
  /**
   * this function collects all vis-groups and prepares them for usage.
   *
   * @returns {*}
   */


  function getVisGroups() {
    var groups = $(".vis-foreground .vis-group:visible");
    var visGroups = {};

    if (!groups || groups.length === 0) {
      return visGroups;
    }

    groups.each(function () {
      if ($(this).html()) {
        var group = getVisGroup($(this));
        visGroups[group.top] = group;
      }
    });
    return visGroups;
  }
  /**
   * this function reads the data objects of the VisJS timeline, to send to the PDF printer.
   * This solution has been added to address the issue where printing the VisJS HTML through
   * headless chrome in the backend, caused timeline items to collide when they fell over the
   * end of a page.
   *
   * see: https://brass.ctrlo.com/issue/805
   */


  function parseTimelineForPdfPrinting() {
    // timeline item positions (.vis-item) are calculated per group (.vis-group),
    // positioned absolute from the top of the group. The group is dynamic in height.
    var visGroups = getVisGroups();

    if (visGroups !== {}) {
      parseVisGroups(visGroups);
    }
  }
  /**
   * This function returns an object property based on its key index
   * @param obj
   * @param key
   * @returns mixed
   */


  function getObjectPropertyByOrderKey(obj) {
    var key = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 0;
    return obj[Object.keys(obj)[key]] || null;
  }
  /**
   * This function returns the first property value of an object, similar to jquery .first()
   * @param obj
   */


  function getFirst(obj) {
    return getObjectPropertyByOrderKey(obj, 0);
  }
  /**
   * This function converts the item rows of a group to the JSON format used by the PDF printer.
   * @param itemRow
   * @returns {string}
   */


  function renderGroupRowItemsJson(itemRow) {
    var itemsJson = '';
    $.each(itemRow, function (index, item) {
      itemsJson += (itemsJson === '' ? '' : ',') + '{' + 'x: ' + item.x + ', ' + 'width: ' + item.width + ', ' + 'text: "' + item.label.trim() + '", ' + 'top: ' + item.top + ', ' + 'textColor: "' + item.textColor + '", ' + 'backgroundColor: "' + item.backgroundColor + '"' + ' }';
    });
    return itemsJson;
  }
  /**
   * This function converts a row of a group to the JSON format used by the PDF printer.
   * @param itemRows
   * @returns {string}
   */


  function renderGroupRowsJson(itemRows) {
    var itemRowsJson = '';
    $.each(itemRows, function (index, itemRow) {
      itemRowsJson += (itemRowsJson === '' ? '' : ',') + '{items: [' + renderGroupRowItemsJson(itemRow) + ']}';
    });
    return itemRowsJson;
  }
  /**
   * This function converts a group to the JSON format used by the PDF printer.
   * @param visGroups
   * @returns {string}
   */


  function renderGroupsJson(visGroups) {
    var groupsJson = '';
    $.each(visGroups, function (index, visGroup) {
      groupsJson += (groupsJson === '' ? '' : ',') + '{label: "' + visGroup.label.text + '", rows: [' + renderGroupRowsJson(visGroup.itemRows) + ']}';
    });
    return 'groups: [' + groupsJson + ']';
  }
  /**
   * This function converts all vis-minor nodes on the top X axis of the timeline to the JSON format used by the
   * PDF printer. When fromX and/or toX is provided, only the nodes in between those X values will be returned.
   * When the first vis-major node is processed, fromX is suspended. This is done because the first node can
   * contain labels that start before the fromX position.
   * @param xAxis
   * @param fromX
   * @param toX
   * @param firstMajor
   * @returns {string}
   */


  function renderXAxisMinorsJson(xAxis) {
    var fromX = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;
    var toX = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;
    var firstMajor = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : true;
    var minorObjects = xAxis.find('.vis-text.vis-minor:not(.vis-measure)');
    var minorsObjectJson = '';

    if (toX !== false) {
      toX = toX - 1;
    }

    $.each(minorObjects, function () {
      var minor = $(this);
      var coordinates = getCssTransformCoordinates(minor); // skip minor labels that do not belong to the current major label when the start and end X position of the major
      // label is provided

      if (fromX !== false) {
        // first major label can have a partial first minor label that is on a lower X position than the major label
        if (firstMajor && toX !== false && coordinates.x >= toX) {
          return true;
        } else if (!firstMajor && (coordinates.x < fromX || toX !== false && coordinates.x >= toX)) {
          return true;
        }
      }

      var minorWidth = getCssPxValue(minor, 'width');
      var minorText = minor.html();
      minorsObjectJson += (minorsObjectJson === '' ? '' : ',') + '{x: ' + coordinates.x + ', width: ' + minorWidth + ', text: "' + minorText + '"}';
    });
    return '[' + minorsObjectJson + ']';
  }
  /**
   * This function gathers and orders the major nodes of the VisJS timeline so that they are
   * returned in chronological order.
   * @param xAxis
   * @returns {*[]}
   */


  function getOrderedMajors(xAxis) {
    var majorObjects = xAxis.find('.vis-text.vis-major:not(.vis-measure)');
    var orderedObjects = [];
    majorObjects.each(function () {
      orderedObjects.push({
        node: $(this),
        x: getCssTransformCoordinates($(this)).x,
        x_end: false
      });
    });
    orderedObjects.sort(function (a, b) {
      return a.x > b.x ? 1 : -1;
    });
    orderedObjects.reverse();
    var prevX = false;
    $(orderedObjects).each(function (index, value) {
      orderedObjects[index].x_end = prevX;
      prevX = orderedObjects[index].x;
    });
    orderedObjects.reverse();
    return orderedObjects;
  }
  /**
   * This function converts all vis-major nodes on the top X axis of the timeline to the JSON format used by the PDF printer.
   * @param xAxis
   * @returns {string}
   */


  function renderXAxisMajorsJson(xAxis) {
    var majorObjects = getOrderedMajors(xAxis);
    var majorsObjectJson = '';

    if (majorObjects && majorObjects.length) {
      $.each(majorObjects, function (index, majorObject) {
        var majorText = majorObject.node.find('div').first().html();
        var minorsJson = renderXAxisMinorsJson(xAxis, majorObject.x, majorObject.x_end, index === 0);
        majorsObjectJson += (majorsObjectJson === '' ? '' : ',') + '{text: "' + majorText + '", x: ' + majorObject.x + ', minor: ' + minorsJson + '}';
      });
    } else {
      majorsObjectJson += '{text: "", x: ' + majorObject.x + ', minor: ' + renderXAxisMinorsJson(xAxis) + '}';
    }

    return '[' + majorsObjectJson + ']';
  }
  /**
   * This function converts all information on the X Axis of the VisJS timeline to the JSON format used by the PDF printer.
   * @param xAxis
   * @returns {string}
   */


  function renderXAxisJson(xAxis) {
    var firstXAxisMinor = xAxis.find('.vis-text.vis-minor:not(.vis-measure)').first();
    var firstXAxisCorrection = getCssTransformCoordinates(firstXAxisMinor).x;
    return 'xAxis: {' + 'height: tableXAxisBarHeight,' + 'x: ' + firstXAxisCorrection + ',' + 'major: ' + renderXAxisMajorsJson(xAxis) + '}';
  }

  function parseVisGroups(visGroups) {
    var targetField = $('#html').first();
    var timeline = $('.vis-timeline').first();
    var xAxis = $(".vis-time-axis.vis-foreground").first();
    var yAxis = $(".vis-panel.vis-left").first();
    var firstXAxisMinor = xAxis.find('.vis-text.vis-minor:not(.vis-measure)').first();
    var firstGroup = getFirst(visGroups) || false;
    var firstRow = firstGroup ? getFirst(firstGroup.itemRows) : false;
    var firstItem = firstRow && firstRow[0] && firstRow[0].node ? firstRow[0].node : false;
    var firstItemContent = firstItem ? firstItem.find('.vis-item-content').first() : false;
    var firstYAxisLabel = $(".vis-label:visible").first();
    var currentTime = $(".vis-current-time");
    var showYAxisBar = getCssPxValue(firstYAxisLabel, 'width') > 0 ? 'true' : 'false';
    var canvasWidth = getCssPxValue(timeline, 'width');
    var fitToPageWidth = $('#fit_to_page_width').prop('checked');
    var zoomLevel = parseInt($('#pdf_zoom').val(), 10);
    var urlJS = targetField.data('url-js');
    var urlCSS = targetField.data('url-css');
    var pageWidth = 1550; // A3 width

    var zoomFactor = zoomLevel / 100 > 0 ? zoomLevel / 100 : 1;
    var pageWidthFactor = fitToPageWidth && pageWidth / canvasWidth > 0 ? pageWidth / canvasWidth : 1;
    var pageScaleFactor = fitToPageWidth ? pageWidthFactor : zoomFactor;
    var fontSize = getCssPxValue(firstItem, 'font-size');
    var lineHeight = getCssPxValue(firstItem, 'line-height');
    var tableXAxisBarHeight = getCssPxValue(xAxis, "height");
    var tableYAxisBarWidth = getCssPxValue(yAxis, "width");
    var borderSize = getCssPxValue(firstItem, 'border-top-width');
    var padding = getCssPxValue(firstItemContent, 'padding-top');
    var xAxisPadding = getCssPxValue(firstXAxisMinor, 'padding-top');
    var currentTimeX = currentTime.length ? getCssTransformCoordinates(currentTime.first()).x : -1;
    var pageData = '{' + renderXAxisJson(xAxis) + ',' + renderGroupsJson(visGroups) + '}';
    $('input#html').val("<!DOCTYPE html>\n<html lang=\"en\">\n  <head>\n    <meta charset=\"UTF-8\">\n    <title>Data</title>\n    <script type=\"application/javascript\" src=\"".concat(urlJS, "/jquery-3.5.1.min.js\"></script>\n    <script type=\"application/javascript\" src=\"").concat(urlJS, "/pdf_printer.js\"></script>\n    <link rel=\"stylesheet\" type=\"text/css\" href=\"").concat(urlCSS, "/pdf_printer.css\">\n    <link rel=\"stylesheet\" type=\"text/css\" href=\"//fonts.googleapis.com/css?family=Open+Sans\">\n  </head>\n  <body>\n    <script type=\"application/javascript\">\n      const pagePrefix = \"page_\";\n      const pageHeight = 1086;\n      const pageWidth = 1550;\n      const pageScaleFactor = ").concat(pageScaleFactor, ";\n      const backgroundColor = \"#fff\";\n      const foregroundColor = \"#333\";\n      const xAxisMinorColor = \"#ccc\";\n      const xAxisTextColor = \"#4d4d4d\";\n      const currentTimeColor = \"#ff7f6e\";\n      const font = \"Open Sans\";\n      const fontSize = ").concat(fontSize, " * pageScaleFactor;\n      const lineHeight = ").concat(lineHeight, " * pageScaleFactor;\n      const tableXAxisBarHeight = ").concat(tableXAxisBarHeight, " * pageScaleFactor;\n      const showYAxisBar = ").concat(showYAxisBar, ";\n      const tableYAxisBarWidth = showYAxisBar ? ").concat(tableYAxisBarWidth, " * pageScaleFactor : 0;\n      const borderSize = ").concat(borderSize, " * pageScaleFactor;\n      const padding = ").concat(padding, " * pageScaleFactor;\n      const xAxisPadding = ").concat(xAxisPadding, " * pageScaleFactor;\n      const currentTimeX = ").concat(currentTimeX, " * pageScaleFactor + tableYAxisBarWidth;\n      const currentTimeThickness = 2 * pageScaleFactor;\n      const pageData = ").concat(pageData, ";\n      let pageNumber = 0;\n      let currentHeight = 0;\n      let canvas = null;\n      let context = null;\n\n      drawTimelinePdf();\n    </script>\n  </body>\n</html>"));
  } // If the perceived background color is dark, switch the font color to white.


  var injectContrastingColor = function injectContrastingColor(dataset) {
    dataset.forEach(function (entry) {
      if (entry.style && typeof entry.style === "string") {
        var backgroundColorMatch = entry.style.match(/background-color:\s(#[0-9A-Fa-f]{6})/);

        if (backgroundColorMatch && backgroundColorMatch[1]) {
          var backgroundColor = backgroundColorMatch[1];
          var backgroundColorLightOrDark = lightOrDark(backgroundColor);

          if (backgroundColorLightOrDark === "dark") {
            entry.style = entry.style + ";" + "color: #FFFFFF;" + "text-shadow: " + "-1px -1px 0.1em " + backgroundColor + ",1px -1px 0.1em " + backgroundColor + ",-1px 1px 0.1em " + backgroundColor + ",1px 1px 0.1em " + backgroundColor + ",1px 1px 2px " + backgroundColor + ",0 0 1em " + backgroundColor + ",0 0 0.2em " + backgroundColor + ";";
          }
        }
      }
    });
  };

  var setupTimeline = function setupTimeline(container, options_in) {
    var records_base64 = container.data("records");
    var json = base64.decode(records_base64);
    var dataset = JSON.parse(json);
    injectContrastingColor(dataset);
    var items = new vis.DataSet(dataset);
    var groups = container.data("groups");
    var json_group = base64.decode(groups);
    groups = JSON.parse(json_group);
    var is_dashboard = !!container.data("dashboard");
    var layout_identifier = $("body").data("layout-identifier"); // See http://visjs.org/docs/timeline/#Editing_Items

    var options = {
      margin: {
        item: {
          horizontal: -1
        }
      },
      moment: function (_moment) {
        function moment(_x) {
          return _moment.apply(this, arguments);
        }

        moment.toString = function () {
          return _moment.toString();
        };

        return moment;
      }(function (date) {
        return moment(date).utc();
      }),
      clickToUse: is_dashboard,
      zoomFriction: 10,
      template: Handlebars.templates.timelineitem,
      orientation: {
        axis: "both"
      }
    }; // Merge any additional options supplied

    for (var attrname in options_in) {
      options[attrname] = options_in[attrname];
    }

    if (container.data("min")) {
      options.start = container.data("min");
    }

    if (container.data("max")) {
      options.end = container.data("max");
    }

    if (container.data("width")) {
      options.width = container.data("width");
    }

    if (container.data("height")) {
      options.width = container.data("height");
    }

    if (!container.data("rewind")) {
      options.editable = {
        add: false,
        updateTime: true,
        updateGroup: false,
        remove: false
      };
      options.multiselect = true;
    }

    var tl = new vis.Timeline(container.get(0), items, options);

    if (groups.length > 0) {
      tl.setGroups(groups);
    } // functionality to add new items on range change


    var persistent_max;
    var persistent_min;
    tl.on("rangechanged", function (props) {
      if (!props.byUser) {
        if (!persistent_min) {
          persistent_min = props.start.getTime();
        }

        if (!persistent_max) {
          persistent_max = props.end.getTime();
        }

        return;
      } // Shortcut - see if we actually need to continue with calculations


      if (props.start.getTime() > persistent_min && props.end.getTime() < persistent_max) {
        update_range_session(props);
        return;
      }

      container.prev("#loading-div").show();
      /* Calculate the range of the current items. This will min/max
            values for normal dates, but for dateranges we need to work
            out the dates of what was retrieved. E.g. the earliest
            end of a daterange will be the start of the range of
            the current items (otherwise it wouldn't have been
            retrieved)
        */
      // Get date range with earliest start

      var val = items.min("start"); // Get date range with latest start

      val = items.max("start");
      var max_start = val ? new Date(val.start) : undefined; // Get date range with earliest end

      val = items.min("end");
      var min_end = val ? new Date(val.end) : undefined; // If this is a date range without a time, then the range will have
      // automatically been altered to add an extra day to its range, in
      // order to show it across the expected period on the timeline (see
      // Timeline.pm). When working out the range to request, we have to
      // remove this extra day, as searching the database will not include it
      // and we will otherwise end up with duplicates being retrieved

      if (min_end && !val.has_time) {
        min_end.setDate(min_end.getDate() - 1);
      } // Get date range with latest end


      val = items.max("end"); // Get earliest single date item

      val = items.min("single");
      var min_single = val ? new Date(val.single) : undefined; // Get latest single date item

      val = items.max("single");
      var max_single = val ? new Date(val.single) : undefined; // Now work out the actual range we have items for

      var have_range = {};

      if (min_end && min_single) {
        // Date range items and single date items
        have_range.min = min_end < min_single ? min_end : min_single;
      } else {
        // Only one or the other
        have_range.min = min_end || min_single;
      }

      if (max_start && max_single) {
        // Date range items and single date items
        have_range.max = max_start > max_single ? max_start : max_single;
      } else {
        // Only one or the other
        have_range.max = max_start || max_single;
      }
      /* haverange now contains the min and max of the current
            range. Now work out whether we need to fill to the left or
            right (or both)
        */


      var from;
      var to;

      if (!have_range.min) {
        from = props.start.getTime();
        to = props.end.getTime();
        load_items(from, to);
      }

      if (props.start < have_range.min) {
        from = props.start.getTime();
        to = have_range.min.getTime();
        load_items(from, to, "to");
      }

      if (props.end > have_range.max) {
        from = have_range.max.getTime();
        to = props.end.getTime();
        load_items(from, to, "from");
      }

      if (!persistent_max || persistent_max < props.end.getTime()) {
        persistent_max = props.end.getTime();
      }

      if (!persistent_min || persistent_min > props.start.getTime()) {
        persistent_min = props.start.getTime();
      }

      container.prev("#loading-div").hide(); // leave to end in case of problems rendering this range

      update_range_session(props);
    });
    var csrf_token = $("body").data("csrf-token");
    /**
     * @param {object} props
     * @returns {void}
     */

    function update_range_session(props) {
      // Do not remember timeline range if adjusting timeline on dashboard
      if (!is_dashboard) {
        $.post({
          url: "/" + layout_identifier + "/data_timeline?",
          data: "from=" + props.start.getTime() + "&to=" + props.end.getTime() + "&csrf_token=" + csrf_token
        });
      }
    }
    /**
     * @param {string} from
     * @param {string} to
     * @param {string} exclusive
     */


    function load_items(from, to, exclusive) {
      /* we use the exclusive parameter to not include ranges
            that go over that date, otherwise we will retrieve
            items that we already have */
      var url = "/" + layout_identifier + "/data_timeline/" + "10" + "?from=" + from + "&to=" + to + "&exclusive=" + exclusive;

      if (is_dashboard) {
        url = url + "&dashboard=1&view=" + container.data("view");
      }

      $.ajax({
        async: false,
        url: url,
        dataType: "json",
        success: function success(data) {
          items.add(data);
        }
      });
    }

    $("#tl_group").on("change", function () {
      var fixedvals = $(this).find(":selected").data("fixedvals");

      if (fixedvals) {
        $("#tl_all_group_values_div").show();
      } else {
        $("#tl_all_group_values_div").hide();
      }
    }).trigger("change");
    return tl;
  }; // timeline PDF printer actions


  $(document).ready(function () {
    var printModal = $("#modal_pdf");

    if (printModal.length) {
      var printForm = printModal.find('form').first();
      var fitToPageField = $('#fit_to_page_width').first();
      var zoomField = $('#pdf_zoom').first(); // add toggle settings for zoom and fit to page functions. You can either zoom, or make the timeline fit to the
      // width of the page, but not both at the same time.

      fitToPageField.change(function () {
        if ($(this).is(":checked")) {
          zoomField.data('original-value', zoomField.val());
          zoomField.val(100);
          zoomField.prop('disabled', true);
        } else {
          var originalFieldValue = parseInt(zoomField.data('original-value'), 10);
          zoomField.val(originalFieldValue > 0 ? originalFieldValue : 100);
          zoomField.prop('disabled', false);
        }
      }); // when the printing modal is submitted, scan the current timeline's structure, to send it to the PDF printer

      printForm.submit(function () {
        parseTimelineForPdfPrinting();
        return true;
      });
    }
  });

  var DataTimelinePage = function DataTimelinePage() {
    var save_elem_sel = "#submit_button",
        cancel_elem_sel = "#cancel_button",
        changed_elem_sel = "#visualization_changes",
        hidden_input_sel = "#changed_data";
    var changed = {};

    var on_move = function on_move(item, callback) {
      changed[item.id] = item;
      var save_button = $(save_elem_sel);

      if (save_button.is(":hidden")) {
        $(window).bind("beforeunload", function (e) {
          var error_msg = "If you leave this page your changes will be lost.";

          if (e) {
            e.returnValue = error_msg;
          }

          return error_msg;
        });
        save_button.closest("form").css("display", "block");
      }

      var changed_item = $("<li>" + item.content + "</li>");
      $(changed_elem_sel).append(changed_item);
      return callback(item);
    };

    var snap_to_day = function snap_to_day(datetime) {
      // A bit of a mess, as the input to this function is in the browser's
      // local timezone, but we need to return it from the function in UTC.
      // Pull the UTC values from the local date, and then construct a new
      // moment using those values.
      var year = datetime.getUTCFullYear();
      var month = ("0" + (datetime.getUTCMonth() + 1)).slice(-2);
      var day = ("0" + datetime.getUTCDate()).slice(-2);
      return timeline.moment.utc("" + year + month + day);
    };

    var options = {
      onMove: on_move,
      snap: snap_to_day
    };
    var tl = setupTimeline($(".visualization"), options);

    var before_submit = function before_submit() {
      var submit_data = _.mapObject(changed, function (val) {
        return {
          column: val.column,
          current_id: val.current_id,
          from: val.start.getTime(),
          to: (val.end || val.start).getTime()
        };
      });

      $(window).off("beforeunload"); // Store the data as JSON on the form

      var submit_json = JSON.stringify(submit_data);
      var data_field = $(hidden_input_sel);
      data_field.attr("value", submit_json);
    }; // Set up form button behaviour


    $(save_elem_sel).bind("click", before_submit);
    $(cancel_elem_sel).bind("click", function () {
      $(window).off("beforeunload");
    });
    var layout_identifier = $("body").data("layout-identifier");

    var on_select = function on_select(properties) {
      var items = properties.items;

      if (items.length == 0) {
        $(".bulk_href").on("click", function (e) {
          e.preventDefault(); // eslint-disable-next-line no-alert

          alert("Please select some records on the timeline first");
          return false;
        });
      } else {
        var hrefs = [];
        $("#delete_ids").empty();
        properties.items.forEach(function (item) {
          var id = item.replace(/\+.*/, "");
          hrefs.push("id=" + id);
          $("#delete_ids").append('<input type="hidden" name="delete_id" value="' + id + '">');
        });
        var href = hrefs.join("&");
        $("#update_href").attr("href", "/" + layout_identifier + "/bulk/update/?" + href);
        $("#clone_href").attr("href", "/" + layout_identifier + "/bulk/clone/?" + href);
        $("#count_delete").text(items.length);
        $(".bulk_href").off();
      }
    };

    tl.on("select", on_select);
    on_select({
      items: []
    });
    setupTippy();
    setupOtherUserViews();
  };

  var AuditPage = function AuditPage() {
    setupOtherUserViews();
    $("#views_other_user_typeahead").on("change", function () {
      $(this).val() || $("#views_other_user_id").val("");
    });
  };

  var setupTreeFields = function () {
    var setupTreeField = function setupTreeField() {
      var $this = $(this);
      var id = $this.data("column-id");
      var multiValue = $this.data("is-multivalue");
      var $treeContainer = $this.find(".tree-widget-container");
      var field = $treeContainer.data("field");
      var layout_identifier = $("body").data("layout-identifier");
      var endNodeOnly = $treeContainer.data("end-node-only");
      var idsAsParams = $treeContainer.data("ids-as-params");
      var treeConfig = {
        core: {
          check_callback: true,
          force_text: true,
          themes: {
            stripes: true
          },
          worker: false,
          data: {
            url: function url() {
              return "/" + layout_identifier + "/tree" + new Date().getTime() + "/" + id + "?" + idsAsParams;
            },
            data: function data(node) {
              return {
                id: node.id
              };
            }
          }
        },
        plugins: []
      };

      if (!multiValue) {
        treeConfig.core.multiple = false;
      } else {
        treeConfig.plugins.push("checkbox");
      }

      $treeContainer.on("changed.jstree", function (e, data) {
        // remove all existing hidden value fields
        $treeContainer.nextAll(".selected-tree-value").remove();
        var selectedElms = $treeContainer.jstree("get_selected", true);
        $.each(selectedElms, function () {
          // store the selected values in hidden fields as children of the element
          var node = $('<input type="hidden" class="selected-tree-value" name="' + field + '" value="' + this.id + '" />').insertAfter($treeContainer);
          var text_value = data.instance.get_path(this, "#");
          node.data("text-value", text_value);
        }); // Hacky: we need to submit at least an empty value if nothing is
        // selected, to ensure the forward/back functionality works. XXX If the
        // forward/back functionality is removed, this can be removed too.

        if (selectedElms.length == 0) {
          $treeContainer.after('<input type="hidden" class="selected-tree-value" name="' + field + '" value="" />');
        }

        $treeContainer.trigger("change");
      });
      $treeContainer.on("select_node.jstree", function (e, data) {
        if (data.node.children.length == 0) {
          return;
        }

        if (endNodeOnly) {
          $treeContainer.jstree(true).deselect_node(data.node);
          $treeContainer.jstree(true).toggle_node(data.node);
        } else if (multiValue) {
          $treeContainer.jstree(true).open_node(data.node);
        }
      });
      $treeContainer.jstree(treeConfig);
      setupJStreeButtons($treeContainer); // hack - see https://github.com/vakata/jstree/issues/1955

      $treeContainer.jstree(true).settings.checkbox.cascade = "undetermined";
    };

    var setupTreeFields = function setupTreeFields(context) {
      var $fields = $('[data-column-type="tree"]', context);
      $fields.filter(function () {
        return $(this).find(".tree-widget-container").length;
      }).each(setupTreeField);
    };

    return function (context) {
      setupTreeFields(context);
    };
  }();

  var setupDependentFields = function () {
    /***
     *
     * Handle the dependency connections between fields
     * via regular expression checks on field values
     *
     * FIXME: It would be an improvement to abstract the
     * different field types in GADS behind a common interface
     * as opposed to using dom-attributes.
     *
     */
    var setupDependentField = function setupDependentField() {
      var condition = this.condition;
      var rules = this.rules;
      var $field = this.field; // In order to hide the relevant fields, we used to trigger a change event
      // on all the fields they depended on. However, this doesn't work for
      // display fields that depend on a filval type field, as the values to
      // check are not rendered on the page until the relevant filtered curval
      // field is opened. As such, use the dependent-not-shown property instead,
      // which is evaluated server-side

      if ($field.data("dependent-not-shown")) {
        $field.hide();
      }

      var test_all = function test_all(condition, rules) {
        if (rules.length == 0) {
          return true;
        }

        var is_shown = false;
        rules.some(function (rule) {
          // Break if returns true
          var $depends = rule.dependsOn;
          var regexp = rule.regexp;
          var is_negative = rule.is_negative;
          var values = getFieldValues($depends, rule.filtered);
          var this_not_shown = is_negative ? false : true;
          $.each(values, function (index, value) {
            // Blank values are returned as undefined for consistency with
            // backend calc code. Convert to empty string, otherwise they will
            // be rendered as the string "undefined" in a regex
            if (value === undefined) value = '';

            if (is_negative) {
              if (regexp.test(value)) this_not_shown = 1;
            } else {
              if (regexp.test(value)) this_not_shown = 0;
            }
          });

          if (!this_not_shown) {
            is_shown = true;
          }

          if (condition) {
            if (condition == "OR") {
              return is_shown; // Whether to break
            }

            if (this_not_shown) {
              is_shown = false;
            }

            return !is_shown; // Whether to break
          }

          return false; // Continue loop
        });
        return is_shown;
      };

      rules.forEach(function (rule) {
        var $depends = rule.dependsOn;

        var processChange = function processChange() {
          test_all(condition, rules) ? $field.show() : $field.hide();
          var $panel = $field.closest(".panel-group");

          if ($panel.length) {
            $panel.find(".linkspace-field").each(function () {
              var none_shown = true; // Assume not showing panel

              if ($(this).css("display") != "none") {
                $panel.show();
                none_shown = false;
                return false; // Shortcut checking any more fields
              }

              if (none_shown) {
                $panel.hide();
              } // Nothing matched

            });
          } // Trigger value check on any fields that depend on this one, e.g.
          // if this one is now hidden then that will change its value to
          // blank. Don't do this if the dependent field is the same as the field
          // with the display condition.


          if ($field.data('column-id') != $depends.data('column-id')) $field.trigger("change");
        }; // If the field depended on is not actually in the form (e.g. if the
        // user doesn't have access to it) then treat it as an empty value and
        // process as normal. Process immediately as the value won't change


        if ($depends.length == 0) {
          processChange();
        } // Standard change of visible form field


        $depends.on("change", function () {
          processChange();
        });
      });
    };

    var setupDependentFields = function setupDependentFields(context) {
      var fields = $("[data-has-dependency]", context).map(function () {
        var dependency = $(this).data("dependency");
        var decoded = JSON.parse(base64.decode(dependency));
        var rules = decoded.rules;
        var condition = decoded.condition;
        var rr = jQuery.map(rules, function (rule) {
          var match_type = rule.operator;
          var is_negative = match_type.indexOf("not") !== -1 ? true : false;
          var regexp = match_type.indexOf("equal") !== -1 ? new RegExp("^" + rule.value + "$", "i") : new RegExp(rule.value, "i");
          var id = rule.id;
          var filtered = false;

          if (rule.filtered) {
            // Whether the field is of type "filval"
            id = rule.filtered;
            filtered = true;
          }

          return {
            dependsOn: $('[data-column-id="' + id + '"]', context),
            regexp: regexp,
            is_negative: is_negative,
            filtered: filtered
          };
        });
        return {
          field: $(this),
          condition: condition,
          rules: rr
        };
      });
      fields.each(setupDependentField); // Now that fields are shown/hidden on page load, for each topic check
      // whether it has zero displayed fields, in which case hide the whole
      // topic (this also happens on field value change dynamically when a user
      // edits the page).
      // This applies to all of: historical view, main record view page, and main
      // record edit page. Use display:none parameter rather than visibility,
      // as fields will not be visible if view-mode is used in a normal record,
      // and also check .table-fields as historical view will not include any
      // of the linkspace-field fields

      $(".panel-group").each(function () {
        var $panel = $(this);

        if (!$panel.find('.table-fields').find('tr').filter(function () {
          return $(this).css("display") != "none";
        }).length && !$panel.find('.linkspace-field').filter(function () {
          return $(this).css("display") != "none";
        }).length) {
          $panel.hide();
        }
      });
    };

    return function (context) {
      setupDependentFields(context);
    };
  }();

  var setupCalcFields = function () {
    var setupCalcField = function setupCalcField() {
      var code = this.code;
      var depends_on = this.depends_on;
      var $field = this.field;
      var params = this.params; // Change standard backend code format to a format that works for
      // evaluating in the browser

      var re = /^function\s+evaluate\s+/gi;
      code = code.replace(re, "function ");
      code = "return " + code;
      depends_on.forEach(function ($depend_on) {
        // Standard change of visible form field that this calc depends on.  When
        // it changes get all the values this code depends on and evaluate the
        // code
        $depend_on.on("change", function () {
          // All the values
          var vars = params.map(function (value) {
            var $depends = $('.linkspace-field[data-name-short="' + value + '"]');
            return getFieldValues($depends, false, true);
          }); // Evaluate the code with the values

          var func = fengari.load(code)();
          var first = vars.shift(); // Use apply() to be able to pass the params as a single array. The
          // first needs to be passed separately so shift it off and do so

          var returnval = func.apply(first, vars); // Update the field holding the code's value

          $field.find('input').val(returnval); // And trigger a change on its parent div to trigger any display
          // conditions

          $field.closest('.linkspace-field').trigger("change");
        });
      });
    };

    var setupCalcFields = function setupCalcFields(context) {
      var fields = $("[data-calc-depends-on]", context).map(function () {
        var dependency = $(this).data("calc-depends-on");
        var depends_on_ids = JSON.parse(base64.decode(dependency));
        var depends_on = jQuery.map(depends_on_ids, function (id) {
          return $('[data-column-id="' + id + '"]', context);
        });
        return {
          field: $(this),
          code: base64.decode($(this).data("code")),
          params: JSON.parse(base64.decode($(this).data("code-params"))),
          depends_on: depends_on
        };
      });
      fields.each(setupCalcField);
    };

    return function (context) {
      setupCalcFields(context);
    };
  }();

  var setupClickToEdit = function () {
    var confirmOnPageExit = function confirmOnPageExit(e) {
      e = e || window.event;
      var message = "Please note that any changes will be lost.";

      if (e) {
        e.returnValue = message;
      }

      return message;
    };

    var setupClickToEdit = function setupClickToEdit(context) {
      $(".click-to-edit", context).on("click", function () {
        var $editToggleButton = $(this);
        this.innerHTML = this.innerHTML === "Edit" ? "View" : "Edit";
        $($editToggleButton.data("viewEl")).toggleClass("expanded");
        $($editToggleButton.data("editEl")).toggleClass("expanded");

        if (this.innerHTML === "View") {
          // If button is showing view then we are on edit page
          window.onbeforeunload = confirmOnPageExit;
        } else {
          window.onbeforeunload = null;
        }
      });
      $(".submit_button").click(function () {
        window.onbeforeunload = null;
      });
      $(".remove-unload-handler").click(function () {
        window.onbeforeunload = null;
      });
    };

    return function (context) {
      setupClickToEdit(context);
    };
  }();

  var setupZebraTable = function () {
    var setupZebraTable = function setupZebraTable(context) {
      $(".table--zebra", context).each(function (_, table) {
        var isOdd = true;
        $(table).children("tbody").children("tr:visible").each(function (_, tr) {
          $(tr).toggleClass("odd", isOdd);
          $(tr).toggleClass("even", !isOdd);
          isOdd = !isOdd;
        });
      });
    };

    return function (context) {
      setupZebraTable(context);
    };
  }();

  var setupClickToViewBlank = function () {
    // Used to hide and then display blank fields when viewing a record
    var setupClickToViewBlank = function setupClickToViewBlank(context) {
      $(".click-to-view-blank", context).on("click", function () {
        var showBlankFields = this.innerHTML === "Show blank values";
        $(".click-to-view-blank-field", context).toggle(showBlankFields);
        this.innerHTML = showBlankFields ? "Hide blank values" : "Show blank values";
        setupZebraTable(context);
      });
    };

    return function (context) {
      setupClickToViewBlank(context);
    };
  }();

  var setupCalculator = function setupCalculator(context) {
    var selector = ".intcalculator";
    var $nodes = $(".fileupload", context);
    $nodes = $(selector, context).closest(".form-group").find("label");
    $nodes.each(function () {
      var $el = $(this);
      var calculator_id = "calculator_div";
      var calculator_elem = $('<div class="dropdown-menu" id="' + calculator_id + '"></div>');
      calculator_elem.css({
        position: "absolute",
        "z-index": 1100,
        display: "none",
        padding: "10px"
      });
      $("body").append(calculator_elem);
      calculator_elem.append('<form class="form-inline">' + '    <div class="form-group btn-group operator" data-toggle="buttons"></div>' + '    <div class="form-group"><input type="text" placeholder="Number" class="form-control"></input></div>' + '    <div class="form-group">' + '        <input type="submit" value="Calculate" class="btn btn-default"></input>' + "    </div>" + "</form>");
      $(document).mouseup(function (e) {
        if (!calculator_elem.is(e.target) && calculator_elem.has(e.target).length === 0) {
          calculator_elem.hide();
        }
      });
      var calculator_operation;
      var integer_input_elem;
      var calculator_button = [{
        action: "add",
        subvaluelabel: "+",
        keypress: ["+"],
        operation: function operation(a, b) {
          return a + b;
        }
      }, {
        action: "subtract",
        label: "-",
        keypress: ["-"],
        operation: function operation(a, b) {
          return a - b;
        }
      }, {
        action: "multiply",
        label: "×",
        keypress: ["*", "X", "x", "×"],
        operation: function operation(a, b) {
          return a * b;
        }
      }, {
        action: "divide",
        label: "÷",
        keypress: ["/", "÷"],
        operation: function operation(a, b) {
          return a / b;
        }
      }];
      var keypress_action = {};
      var operator_btns_elem = calculator_elem.find(".operator");

      for (var i in calculator_button) {
        (function () {
          var btn = calculator_button[i];
          var button_elem = $('<label class="btn btn-primary" style="width:40px">' + '<input type="radio" name="op" class="btn_label_' + btn.action + '">' + btn.label + "</input>" + "</label>");
          operator_btns_elem.append(button_elem);
          button_elem.on("click", function () {
            calculator_operation = btn.operation;
            calculator_elem.find(":text").focus();
          });

          for (var j in btn.keypress) {
            var keypress = btn.keypress[j];
            keypress_action[keypress] = btn.action;
          }
        })();
      }

      calculator_elem.find(":text").on("keypress", function (e) {
        var key_pressed = e.key;

        if (key_pressed in keypress_action) {
          var button_selector = ".btn_label_" + keypress_action[key_pressed];
          calculator_elem.find(button_selector).click();
          e.preventDefault();
        }
      });
      calculator_elem.find("form").on("submit", function (e) {
        var new_value = calculator_operation(+integer_input_elem.val(), +calculator_elem.find(":text").val());
        integer_input_elem.val(new_value);
        calculator_elem.hide();
        e.preventDefault();
      });
      var $calc_button = $('<span class="btn-xs btn-link openintcalculator">Calculator</span>');
      $calc_button.insertAfter($el).on("click", function (e) {
        var calc_elem = $(e.target);
        var container_elem = calc_elem.closest(".form-group");
        var input_elem = container_elem.find(selector);
        var container_y_offset = container_elem.offset().top;
        var container_height = container_elem.height();
        var calculator_y_offset;
        var calc_div_height = $("#calculator_div").height();

        if (container_y_offset > calc_div_height) {
          calculator_y_offset = container_y_offset - calc_div_height;
        } else {
          calculator_y_offset = container_y_offset + container_height;
        }

        calculator_elem.css({
          top: calculator_y_offset,
          left: container_elem.offset().left
        });
        var calc_input = calculator_elem.find(":text");
        calc_input.val("");
        calculator_elem.show();
        calc_input.focus();
        integer_input_elem = input_elem;
      });
    });
  };

  var EditPage = function EditPage(context) {
    Linkspace.debug("Record edit JS firing");
    setupTreeFields(context);
    setupDependentFields(context);
    setupCalcFields(context);
    setupClickToEdit(context);
    setupClickToViewBlank(context);
    setupCalculator(context);
    setupZebraTable(context);
  };

  var GraphPage = function GraphPage() {
    $("#is_shared").change(function () {
      $("#group_id_div").toggle(this.checked);
    }).change();
    $(".date-grouping").change(function () {
      if ($("#trend").val() || $("#set_x_axis").find(":selected").data("is-date")) {
        $("#x_axis_date_display").show();
      } else {
        $("#x_axis_date_display").hide();
      }
    }).change();
    $("#trend").change(function () {
      if ($(this).val()) {
        $("#group_by_div").hide();
      } else {
        $("#group_by_div").show();
      }
    }).change();
    $("#x_axis_range").change(function () {
      if ($(this).val() == "custom") {
        $("#custom_range").show();
      } else {
        $("#custom_range").hide();
      }
    }).change();
    $("#y_axis_stack").change(function () {
      if ($(this).val() == "sum") {
        $("#y_axis_div").show();
      } else {
        $("#y_axis_div").hide();
      }
    }).change();
  };

  var setupDataTables = function () {
    var setupDataTables = function setupDataTables(context) {
      $(".dtable", context).each(function () {
        var pagelength = $(this).data("page-length") || 10;
        var params = {
          order: [[1, "asc"]],
          pageLength: pagelength
        };
        var type = $(this).data("type");

        if (type == "users") {
          // Rendering function to produce HTML-encoded data from plain text
          var $render = function $render(data, type, row, meta) {
            if (type == "filter" || type == "sort" || type == "type") {
              return data;
            } else if (type == "display") {
              return $('<div />').text(data).html();
            } else {
              return data;
            }
          };

          params.ajax = '/api/users';
          params.serverSide = true;
          params.processing = true;
          var $table = $(this);
          $.ajax('/api/users?cols=1', {
            success: function success(data) {
              data = data.map(function (x) {
                x.render = $render;
                return x;
              });
              data.unshift({
                name: 'id',
                data: 'id',
                render: function render(data, type, row, meta) {
                  if (type == "display") {
                    return '<a href="/user/' + data + '">' + data + '</a>';
                  } else {
                    return data;
                  }
                }
              });
              params.columns = data;
              $table.dataTable(params);
            }
          });
        } else {
          $(this).dataTable(params);
        }
      });
    };

    return function (context) {
      setupDataTables(context);
    };
  }();

  var GraphsPage = function GraphsPage(context) {
    setupDataTables(context); // When a search is entered in a datatables table, selected graphs that are
    // filtered will not be submitted. Therefore, find all selected values and
    // add them to the form

    $("#submit").on("click", function () {
      $(".dtable").DataTable().column(0).nodes().to$().each(function () {
        var $cell = $(this);
        var $checkbox = $cell.find("input");

        if ($checkbox.is(":checked")) {
          $('<input type="hidden" name="graphs">').val($checkbox.val()).appendTo("form");
        }
      });
    });
  };

  // Functions for graph plotting
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
  }; // At the moment, do_plot_json needs to be exported globally, as it is used by
  // Phantomjs to produce PNG versions of the graphs. Once jqplot has been
  // replaced by a more modern graphing library, the PNG/Phantomjs functionality
  // will probably unneccessary if that functionality is built into the library.


  var do_plot_json = window.do_plot_json = function (plotData, options_in) {
    plotData = JSON.parse(base64.decode(plotData));
    options_in = JSON.parse(base64.decode(options_in));
    do_plot(plotData, options_in);
  };

  var IndexPage = function IndexPage(context) {
    $(document).ready(function () {
      $(".dashboard-graph", context).each(function () {
        var graph = $(this);
        var graph_data = graph.data("plot-data");
        var options_in = graph.data("plot-options");
        do_plot_json(graph_data, options_in);
      });
      $(".visualization", context).each(function () {
        setupTimeline($(this), {});
      });
      $(".globe", context).each(function () {
        setupGlobeByClass($(this));
      });
      setupTippy(context);
    });
  };

  var SetupTabPanel = function SetupTabPanel() {
    var $this = $(this);
    var $tabs = $this.find('[role="tab"]');
    var $panels = $this.find('[role="tabpanel"]');
    var indexedTabs = [];
    $tabs.each(function (i) {
      indexedTabs[i] = $(this);
      $(this).data("index", i);
    });

    var selectTab = function selectTab(e) {
      if (e) {
        e.preventDefault();
      }

      var $thisTab = $(this);

      if ($thisTab.attr("aria-selected") === "true") {
        return false;
      }

      var $thisPanel = $panels.filter($thisTab.attr("href"));
      var $activeTab = $tabs.filter('[aria-selected="true"]');
      var $activePanel = $panels.filter(".active");
      $activeTab.attr("aria-selected", false);
      $activePanel.removeClass("active");
      $thisTab.attr("aria-selected", true);
      $thisPanel.addClass("active");
      $thisTab.attr("tabindex", "0");
      $tabs.filter('[aria-selected="false"]').attr("tabindex", "-1");
      return false;
    };

    var moveTab = function moveTab(e) {
      var $thisTab = $(this);
      var index = $thisTab.data("index");
      var k = e.keyCode;
      var left = Linkspace.constants.ARROW_LEFT,
          right = Linkspace.constants.ARROW_RIGHT;

      if ([left, right].indexOf(k) < 0) {
        return;
      }

      var $nextTab;

      if (k === left && ($nextTab = indexedTabs[index - 1]) || k === right && ($nextTab = indexedTabs[index + 1])) {
        selectTab.call($nextTab);
        $nextTab.focus();
      }
    };

    $tabs.on("click", selectTab);
    $tabs.on("keyup", moveTab);
    $tabs.filter('[aria-selected="false"]').attr("tabindex", "-1");
  };

  var LayoutPage = function LayoutPage(context) {
    $(".tab-interface").each(SetupTabPanel);
    var $config = $("#permission-configuration");
    var $rule = $(".permission-rule", context);
    var $ruleTemplate = $("#permission-rule-template");
    var $cancelRuleButton = $rule.find("button.cancel-permission");
    var $addRuleButton = $rule.find("button.add-permission");

    var closePermissionConfig = function closePermissionConfig() {
      $config.find("input").each(function () {
        $(this).prop("checked", false);
      });
      $config.attr("hidden", "");
      $("#configure-permissions").removeAttr("hidden").focus();
    };

    var handlePermissionChange = function handlePermissionChange() {
      var $permission = $(this);
      var groupId = $permission.data("group-id");
      var $editButton = $permission.find("button.edit");
      var $deleteButton = $permission.find("button.delete");
      var $okButton = $permission.find("button.ok");
      $permission.find("input").on("change", function () {
        var pClass = "permission-" + $(this).data("permission-class");
        var checked = $(this).prop("checked");
        $permission.toggleClass(pClass, checked);

        if (checked) {
          return;
        }

        $(this).siblings("div").find("input").each(function () {
          $(this).prop(checked);
          pClass = "permission-" + $(this).data("permission-class");
          $permission.toggleClass(pClass, checked);
        });
      });
      $editButton.on("expand", function () {
        $permission.addClass("edit");
        $permission.find(".group-name").focus();
      });
      $deleteButton.on("click", function () {
        $("#permissions").removeClass("permission-group-" + groupId);
        $permission.remove();
      });
      $okButton.on("click", function () {
        $permission.removeClass("edit");
        $okButton.parent().removeClass("expanded");
        $editButton.attr("aria-expanded", false).focus();
      });
    };

    $cancelRuleButton.on("click", closePermissionConfig);
    $addRuleButton.on("click", function () {
      var $newRule = $($ruleTemplate.html());
      var $currentPermissions = $("#current-permissions ul");
      var $selectedGroup = $config.find("option:selected");
      var groupId = $selectedGroup.val();
      $config.find("input").each(function () {
        var $input = $(this);
        var state = $input.prop("checked");

        if (state) {
          $newRule.addClass("permission-" + $input.data("permission-class").replace(/_/g, "-"));
        }

        $newRule.find("input#" + $input.attr("id")).prop("checked", state).attr("id", $input.attr("id") + groupId).attr("name", $input.attr("name") + groupId).next("label").attr("for", $input.attr("id"));
      });
      $newRule.appendTo($currentPermissions);
      $newRule.attr("data-group-id", groupId);
      $("#permissions").addClass("permission-group-" + groupId);
      $newRule.find(".group-name").text($selectedGroup.text());
      $newRule.find("button.edit").on("click", onDisclosureClick);
      handlePermissionChange.call($newRule);
      closePermissionConfig();
    });
    $("#configure-permissions").on("click", function () {
      var $permissions = $("#permissions");
      var selected = false;
      $("#permission-configuration").find("option").each(function () {
        var $option = $(this);
        $option.removeAttr("disabled");

        if ($permissions.hasClass("permission-group-" + $option.val())) {
          $option.attr("disabled", "");
        } else {
          // make sure the first non-disabled option gets selected
          if (!selected) {
            $option.attr("selected", "");
            selected = true;
          }
        }
      });
      $(this).attr("hidden", "");
      $("#permission-configuration").removeAttr("hidden");
      $(this).parent().find("h4").focus();
    });
    $("#current-permissions .permission").each(handlePermissionChange);
  };

  var LoginPage = function LoginPage() {
    $(".remember-me").each(function () {
      var $widget = $(this);
      var $checkbox = $widget.find("input:checkbox");
      $checkbox.on("change", updateDisplay);
      /**
       *
       */

      function updateDisplay() {
        var isChecked = $checkbox.is(":checked");
        $checkbox.toggleClass("remember--checked", isChecked);
      }
    });
    $(".show-password").each(function () {
      var $widget = $(this);
      var $checkbox = $widget.find("input:checkbox");
      var passwordEl = document.querySelector("input[name=password]");
      $checkbox.on("change", updateDisplay2);
      /**
       *
       */

      function updateDisplay2() {
        var isChecked = $checkbox.is(":checked");
        $checkbox.toggleClass("show_password--checked", isChecked);
        passwordEl.type = isChecked ? "text" : "password";
      }
    });
  };

  var MetricPage = function MetricPage() {
    $("#modal_metric").on("show.bs.modal", function (event) {
      var button = $(event.relatedTarget);
      var metric_id = button.data("metric_id");
      $("#metric_id").val(metric_id);

      if (metric_id) {
        $("#delete_metric").show();
      } else {
        $("#delete_metric").hide();
      }

      var target_value = button.data("target_value");
      $("#target_value").val(target_value);
      var x_axis_value = button.data("x_axis_value");
      $("#x_axis_value").val(x_axis_value);
      var y_axis_grouping_value = button.data("y_axis_grouping_value");
      $("#y_axis_grouping_value").val(y_axis_grouping_value);
    });
  };

  var PurgePage = function PurgePage() {
    $("#selectall").click(function () {
      $(".record_selected").prop("checked", this.checked);
    });
  };

  var SytemPage = function SytemPage() {
    setupHtmlEditor();
  };

  var UserPage = function UserPage(context) {
    setupDataTables(context);
    $(document).on("click", ".cloneme-user", function () {
      var parent = $(this).parents(".limit-to-view");
      var cloned = parent.clone();
      cloned.removeAttr("id").insertAfter(parent);
    });
    $(document).on("click", ".removeme-user", function () {
      var parent = $(this).parents(".limit-to-view");

      if (parent.siblings(".limit-to-view").length > 0) {
        parent.remove();
      }
    });
  };

  var setupPageSpecificCode = function () {
    var pages = {
      config: ConfigPage,
      data_calendar: DataCalendarPage,
      data_globe: DataGlobePage,
      data_graph: DataGraphPage,
      data_table: DataTablePage,
      data_timeline: DataTimelinePage,
      audit: AuditPage,
      edit: EditPage,
      graph: GraphPage,
      graphs: GraphsPage,
      index: IndexPage,
      layout: LayoutPage,
      login: LoginPage,
      metric: MetricPage,
      purge: PurgePage,
      system: SytemPage,
      user: UserPage
    };

    var setupPageSpecificCode = function setupPageSpecificCode(context) {
      var page = $("body").data("page").match(/^(.*?)(:?\/\d+)?$/);

      if (page === null) {
        return;
      }

      var setupPageComponent = pages[page[1]];

      if (setupPageComponent !== undefined) {
        setupPageComponent(context);
      }
    };

    return function (context) {
      setupPageSpecificCode(context);
    };
  }();

  var setupPlaceholder = function () {
    var setupPlaceholder = function setupPlaceholder(context) {
      $("input, text", context).placeholder();
    };

    return function (context) {
      setupPlaceholder(context);
    };
  }();

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
  }();

  var setupPurge = function () {
    var setupSelectAll = function setupSelectAll(context) {
      $("#selectall", context).click(function () {
        $(".record_selected", context).prop("checked", this.checked);
      });
    };

    return function (context) {
      setupSelectAll(context);
    };
  }();

  var setupRecordPopup = function () {
    var setupRecordPopup = function setupRecordPopup(context) {
      $(".record-popup", context).on("click", function () {
        var record_id = $(this).data("record-id");
        var version_id = $(this).data("version-id");
        var m = $("#readmore_modal");
        var modal = m.find(".modal-body");
        modal.text("Loading...");
        var url = "/record_body/" + record_id;

        if (version_id) {
          url = url + "?version_id=" + version_id;
        }

        modal.load(url, null, function () {
          setupZebraTable(modal);
        });
        m.modal(); // Stop the clicking of this pop-up modal causing the opening of the
        // overall record for edit in the data table

        event.stopPropagation();
      });
    };

    return function (context) {
      setupRecordPopup(context);
    };
  }();

  var setupSubmitListener = function () {
    var setupSubmitListener = function setupSubmitListener(context) {
      $(".edit-form", context).on("submit", function () {
        var $button = $(document.activeElement);
        $button.prop("disabled", true);

        if ($button.prop("name")) {
          $button.after('<input type="hidden" name="' + $button.prop("name") + '" value="' + $button.val() + '" />');
        }
      });
    };

    return function (context) {
      setupSubmitListener(context);
    };
  }();

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
  }();

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
  }();

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

  window.Linkspace = {
    constants: {
      ARROW_LEFT: 37,
      ARROW_RIGHT: 39
    },
    init: function init(context) {
      setupAccessibility(context);
      setupBuilder(context);
      setupCalendar(context);
      setupColumnFilters(context);
      setupDisclosureWidgets(context);
      setupEdit(context);
      setupFileUpload(context);
      setupFirstInputFocus(context);
      setupGlobeById(context);
      setupHtmlEditor(context);
      setupLayout(context);
      setupLessMoreWidgets(context);
      setupLogin(context);
      setupMetric(context);
      setupMyGraphs(context);
      setupPageSpecificCode(context);
      setupPlaceholder(context);
      setupPopover(context);
      setupPurge(context);
      setupRecordPopup(context);
      setupSelectWidgets(context);
      setupSubmitListener(context);
      setupTable(context);
      setupUserPermission(context);
      setupView(context);
    },
    debug: function debug(msg) {
      // eslint-disable-next-line no-console
      if (typeof console !== "undefined" && console.debug) {
        // eslint-disable-next-line no-console
        console.debug("[LINKSPACE]", msg);
      }
    },
    error: function error(msg) {
      // eslint-disable-next-line no-console
      if (typeof console !== "undefined" && console.error) {
        // eslint-disable-next-line no-console
        console.error("[LINKSPACE]", msg);
      }
    }
  };
  window.Linkspace.init();

}());
