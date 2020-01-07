'use strict';

if (!Function.prototype.bind) {
    Function.prototype.bind = function (oThis) {
        if (typeof this !== "function") {
            // closest thing possible to the ECMAScript 5 internal IsCallable function
            throw new TypeError("Function.prototype.bind - what is trying to be bound is not callable");
        }

        var aArgs = Array.prototype.slice.call(arguments, 1),
            fToBind = this,
            fNOP = function () {},
            fBound = function () {
                return fToBind.apply(this instanceof fNOP && oThis
                                    ? this
                                    : oThis,
                                    aArgs.concat(Array.prototype.slice.call(arguments)));
            };

        fNOP.prototype = this.prototype;
        fBound.prototype = new fNOP();

        return fBound;
    };
}

if (!Array.prototype.filter)
{
    Array.prototype.filter = function(fun /*, thisp */)
    {
        if (this === void 0 || this === null)
            throw new TypeError();

        var t = Object(this);
        var len = t.length >>> 0;
        if (typeof fun !== "function")
            throw new TypeError();

        var res = [];
        var thisp = arguments[1];
        for (var i = 0; i < len; i++)
        {
            if (i in t)
            {
                var val = t[i]; // in case fun mutates this
                if (fun.call(thisp, val, i, t))
                    res.push(val);
            }
        }

        return res;
    };
}

if (!Array.prototype.includes) {
    Array.prototype.includes = function(obj) {
        var newArr = this.filter(function(el) {
            return el == obj;
        });
        return newArr.length > 0;
    };
}

if (typeof Array.prototype.forEach != 'function') {
    Array.prototype.forEach = function(callback){
      for (var i = 0; i < this.length; i++){
        callback.apply(this, [this[i], i, this]);
      }
    };
}

// This wrapper fixes wrong placement of datepicker. See
// https://github.com/uxsolutions/bootstrap-datepicker/issues/1941
var originaldatepicker = $.fn.datepicker;

$.fn.datepicker = function () {
    var result = originaldatepicker.apply(this, arguments);

    this.on('show', function (e) {
        var $target = $(this),
            $picker = $target.data('datepicker').picker,
            top;

        if ($picker.hasClass('datepicker-orient-top')) {
            top = $target.offset().top - $picker.outerHeight() - parseInt($picker.css('marginTop'));
        } else {
            top = $target.offset().top + $target.outerHeight() + parseInt($picker.css('marginTop'));
        }

        $picker.offset({top: top});
    });

    return result;
}

window.guid = function() {
    var S4 = function() {
        return (((1+Math.random())*0x10000)|0).toString(16).substring(1);
    };
    return (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4());
}

var setupCalculator = function (context) {

    var selector = '.intcalculator';
    var $nodes = $('.fileupload', context);
    var $nodes = $(selector, context).closest('.form-group').find('label');

    $nodes.each(function () {
        var $el = $(this);
        var calculator_id   = 'calculator_div';
        var calculator_elem = $('<div class="dropdown-menu" id="' + calculator_id + '"></div>');
        calculator_elem.css({
            position: 'absolute',
            'z-index': 1100,
            display: 'none',
            padding: '10px'
        });
        $('body').append(calculator_elem);

        calculator_elem.append(' \
            <form class="form-inline"> \
                <div class="form-group btn-group operator" data-toggle="buttons"></div> \
                <div class="form-group"><input type="text" placeholder="Number" class="form-control"></input></div> \
                <div class="form-group"> \
                    <input type="submit" value="Calculate" class="btn btn-default"></input> \
                </div> \
            </form> \
        ');

        $(document).mouseup(function (e)
        {
            if (!calculator_elem.is(e.target)
                && calculator_elem.has(e.target).length === 0)
            {
                calculator_elem.hide();
            }
        });

        var calculator_operation;
        var integer_input_elem;

        var calculator_button = [
            {
                action:     'add',
                subvaluelabel:      '+',
                keypress:   [ '+' ],
                operation:  function (a, b) { return a + b; }
            },
            {
                action:     'subtract',
                label:      '-',
                keypress:   [ '-' ],
                operation:  function (a, b) { return a - b; }
            },
            {
                action:     'multiply',
                label:      '×',
                keypress:   [ '*', 'X', 'x', '×' ],
                operation:  function (a, b) { return a * b; }
            },
            {
                action:     'divide',
                label:      '÷',
                keypress:   [ '/', '÷' ],
                operation:  function (a, b) { return a / b; }
            }
        ];
        var keypress_action = {};
        var operator_btns_elem = calculator_elem.find('.operator');
        for (var i in calculator_button) {
            ( function () {
                var btn = calculator_button[i];
                var button_elem = $(
                    '<label class="btn btn-primary" style="width:40px">'
                    + '<input type="radio" name="op" class="btn_label_' + btn.action + '">'
                    + btn.label
                    + '</input>'
                    + '</label>'
                );
                operator_btns_elem.append(button_elem);
                button_elem.on('click', function() {
                    calculator_operation = btn.operation;
                    calculator_elem.find(':text').focus();
                });
                for (var j in btn.keypress) {
                    var keypress = btn.keypress[j];
                    keypress_action[keypress] = btn.action;
                }
            })();
        }

        calculator_elem.find(':text').on('keypress', function (e) {
            var key_pressed = e.key;
            if (key_pressed in keypress_action) {
                var button_selector = '.btn_label_'
                    + keypress_action[key_pressed];
                calculator_elem.find(button_selector).click();
                e.preventDefault();
            }
        });
        calculator_elem.find('form').on('submit', function (e) {
            var new_value = calculator_operation(
                + integer_input_elem.val(),
                + calculator_elem.find(':text').val()
            );
            integer_input_elem.val(new_value);
            calculator_elem.hide();
            e.preventDefault();
        });

        var $calc_button =
            $('<span class="btn-xs btn-link openintcalculator">Calculator</span>');
        $calc_button.insertAfter($el).on('click', function (e) {
            var calc_elem = $(e.target);
            var container_elem = calc_elem.closest('.form-group');
            var input_elem = container_elem.find(selector);

            var container_y_offset = container_elem.offset().top;
            var container_height = container_elem.height();
            var calculator_y_offset;
            var calc_div_height = $('#calculator_div').height();
            if (  container_y_offset > calc_div_height ) {
                calculator_y_offset = container_y_offset - calc_div_height;
            }
            else {
                calculator_y_offset = container_y_offset + container_height;
            }
            calculator_elem.css({
                top: calculator_y_offset,
                left: container_elem.offset().left
            });
            var calc_input = calculator_elem.find(':text');
            calc_input.val('');
            calculator_elem.show();
            calc_input.focus();
            integer_input_elem = input_elem;
        });
    });
}

/*
 * A SelectWidget is a custom disclosure widget
 * with multi or single options selectable.
 * SelectWidgets can depend on each other;
 * for instance if Value "1" is selected in Widget "A",
 * Widget "B" might not be displayed.
 */
var SelectWidget = function (multi) {

    var $selectWidget = this;
    var $widget = this.find('.form-control');
    var isSingle = this.hasClass('single');
    var $trigger = $widget.find('[aria-expanded]');
    var $current = this.find('.current');
    var $available = this.find('.available');
    var $availableItems = this.find('.available .answer input');
    var $moreInfoButtons = this.find('.available .answer .more-info');
    var $target  = this.find('#' + $trigger.attr('aria-controls'));
    var $currentItems = $current.find("[data-list-item]");
    var $answers = this.find('.answer');
    var $fakeInput = null;
    var $search = this.find('.form-control-search');
    var lastFetchParams = null;


    var connect = function() {
        if (multi) {
            $currentItems.each(connectMulti(updateState));
        } else {
            connectSingle();
        }
    }

    var connectMulti = function (update) {
        return function () {
            var $item = $(this);
            var itemId = $item.data('list-item');
            var $associated = $('#' + itemId);
            $associated.unbind('change');
            $associated.on('change', function (e) {
                e.stopPropagation();
                if ($(this).prop('checked')) {
                    $item.removeAttr('hidden');
                } else {
                    $item.attr('hidden', '');
                }
                update();
            });

            $associated.unbind('keydown');
            $associated.on('keydown', function(e) {
                var key = e.which || e.keyCode;
                switch (key) {
                    case 38: // UP
                    case 40: // DOWN
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
                        $(this).trigger('click');
                        break;
                };
            });
        };
    };

    var connectSingle = function () {
        $currentItems.each(function(_, item) {
            var $item = $(item);
            var itemId = $item.data('list-item');
            var $associated = $('#' + itemId);

            $associated.unbind('click');
            $associated.on('click', function(e){
                e.stopPropagation();
            });

            $associated.parent().unbind('keypress');
            $associated.parent().on('keypress', function(e) {
                // KeyCode Enter or Spacebar
                if (e.keyCode === 13 || e.keyCode === 32) {
                    e.preventDefault();
                    $(this).trigger('click');
                }
            })

            $associated.parent().unbind('click');
            $associated.parent().on('click', function(e){
                e.stopPropagation();
                $currentItems.each(function () {
                    $(this).attr('hidden', '');
                });

                $current.toggleClass('empty', false);
                $item.removeAttr('hidden');

                $widget.trigger('change');
                collapse($widget, $trigger, $target);
            });
        });
    };

    var currentLi = function(multi, field, value, label, checked) {
        if (multi && !value) {
            return $('<li class="none-selected">blank</li>');
        }

        var valueId = value ? field + "_" + value : field + "__blank";
        var className = value ? "": "current__blank"
        var deleteButton = multi ? '<button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete" title="delete" tabindex="-1">&times;</button>' : "";
        return $('<li ' + (checked ? '' : 'hidden') + ' data-list-item="' + valueId + '" class="' + className + '">' + label + deleteButton + '</li>');
    }

    var availableLi = function(multi, field, value, label, checked) {
        if (multi && !value) {
            return null;
        }

        var valueId = value ? field + "_" + value : field + "__blank";
        var classNames = value ? "answer" : "answer answer--blank";

        var detailsButton = '<span class="details">' +
            '<button type="button" class="more-info" data-record-id="' + value + '" aria-describedby="' + valueId + '_label" aria-haspopup="listbox">' +
                'Details' +
            '</button>' +
        '</span>';

        return $('<li class="' + classNames + '">' +
            '<span class="control">' +
                '<label id="' + valueId + '_label" for="' + valueId + '">' +
                    '<input id="' + valueId + '" type="' + (multi ? "checkbox" : "radio") + '" name="' + field + '" ' + (checked ? 'checked' : '') + ' value="' + (value || '') + '" class="' + (multi ? "" : "visually-hidden") + '" aria-labelledby="' + valueId  + '_label">' +
                    '<span role="option">' + label + '</span>' +
                '</label>' +
            '</span>' +
            (value ? detailsButton : '') +
        '</li>');
    }

    var fetchOptions = function() {
        var field = $selectWidget.data("field");
        var multi = $selectWidget.hasClass("multi");
        var filterEndpoint = $selectWidget.data("filter-endpoint");
        var filterFields = $selectWidget.data("filter-fields");
        var submissionToken = $selectWidget.data("submission-token");
        if (!$.isArray(filterFields)) {
            if (typeof(console) !== 'undefined' && console.error) {
                console.error("Invalid data-filter-fields found. It should be a proper JSON array of fields.");
            }
        }

        var currentValues = $available.find("input:checked").map(function() { return parseInt($(this).val()); }).get();

        // Collect values of linked fields
        var values = ['submission-token=' + submissionToken];
        $.each(filterFields, function(_, field) {
            $("input[name=" + field + "]").each(function(_, input) {
                var $input = $(input);
                switch($input.attr("type")) {
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
                    case "hidden": // Tree values stored as hidden field
                        values.push(field + "=" + $input.val());
                        break;
               };
            });
        });

        // Bail out if the options haven't changed
        var fetchParams = values.join("&");
        if (lastFetchParams === fetchParams) {
            return;
        }
        lastFetchParams = null;

        $available.find(".answer").remove();
        $available.find(".spinner").removeAttr('hidden');

        $.getJSON(filterEndpoint + "?" + fetchParams, function(data) {
            $currentItems.remove();

            if (data.error === 0) {
                var checked = currentValues.includes(NaN);
                $search.parent().before(currentLi(multi, field, null, "blank", checked));
                $available.append(availableLi(multi, field, null, 'blank', checked));

                $.each(data.records, function(recordIndex, record) {
                    var checked = currentValues.includes(record.id);
                    $search.parent().before(currentLi(multi, field, record.id, record.label, checked));
                    $available.append(availableLi(multi, field, record.id, record.label, checked));
                });

                $currentItems = $current.find("[data-list-item]");
                $available = $selectWidget.find('.available');
                $availableItems = $selectWidget.find('.available .answer input');
                $moreInfoButtons = $selectWidget.find('.available .answer .more-info');
                $answers = $selectWidget.find('.answer');

                updateState();
                connect();

                $availableItems.on('blur', possibleCloseWidget);
                $moreInfoButtons.on('blur', possibleCloseWidget);

                lastFetchParams = fetchParams;
            } else {
                var errorMessage = data.error === 1 ? data.message : "Oops! Something went wrong.";
                var errorLi = $('<li class="answer answer--blank alert alert-danger"><span class="control"><label>' + errorMessage + '</label></span></li>');
                $available.append(errorLi);
            }
        })
        .fail(function(jqXHR, textStatus, textError) {
            var errorMessage = "Oops! Something went wrong.";
            console.log("Failed to make request to " + filterEndpoint + ": " + textStatus + ": " + textError);
            var errorLi = $('<li class="answer answer--blank alert alert-danger"><span class="control"><label>' + errorMessage + '</label></span></li>');
            $available.append(errorLi);
        })
        .always(function() {
            $available.find(".spinner").attr('hidden', '');
        });
    }

    var expand = function($widget, $trigger, $target) {
        if ($trigger.attr('aria-expanded') === "true") {
            return;
        }

        $selectWidget.addClass("select-widget--open");
        $trigger.attr('aria-expanded', true);

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
        $target.toggleClass('available--top', expandAtTop);
        $target.removeAttr('hidden');

        if ($search.get(0) !== document.activeElement) {
            $search.focus();
        }
    }

    var collapse = function($widget, $trigger, $target) {
        $selectWidget.removeClass("select-widget--open");
        $trigger.attr('aria-expanded', false);

        // Add a small delay when hiding the select widget, to allow IE to also
        // fire the default actions when selecting a radio button by clicking on
        // its label. When the input is hidden on the click event of the label
        // the input isn't actually being selected.
        setTimeout(function() {
            $search.val('');
            $target.attr('hidden', '');
            $answers.removeAttr('hidden');
        }, 50);
    }

    var updateState = function () {
        var $visible = $current.children('[data-list-item]:not([hidden])');

        $current.toggleClass('empty', $visible.length === 0);
        $widget.trigger('change');
    };

    updateState();

    connect();

    $widget.unbind('click');
    $widget.on('click', function() {
        if ($trigger.attr('aria-expanded') === "true") {
            collapse($widget, $trigger, $target);
        } else {
            expand($widget, $trigger, $target);
        }
    });

    function possibleCloseWidget(e) {
        var newlyFocussedElement = e.relatedTarget || document.activeElement;
        if (!$selectWidget.find(newlyFocussedElement).length && newlyFocussedElement && !$(newlyFocussedElement).is(".modal, .page") && $selectWidget.get(0).parentNode !== newlyFocussedElement) {
            collapse($widget, $trigger, $target);
        }
    }

    $search.unbind('blur');
    $search.on('blur', possibleCloseWidget);

    $availableItems.unbind('blur');
    $availableItems.on('blur', possibleCloseWidget);

    $moreInfoButtons.unbind('blur');
    $moreInfoButtons.on('blur', possibleCloseWidget);

    $(document).on('click', function(e) {
        var clickedOutside = !this.is(e.target) && this.has(e.target).length === 0;
        var clickedInDialog = $(e.target).closest(".modal").length !== 0;
        if (clickedOutside && !clickedInDialog) {
            collapse($widget, $trigger, $target);
        }
    }.bind(this));

    $(document).keyup(function(e) {
        if (e.keyCode == 27) {
            collapse($widget, $trigger, $target);
        }
    });

    function expandWidgetHandler(e) {
      e.stopPropagation();
      expand($widget, $trigger, $target);
    }

    $widget.delegate('.select-widget-value__delete', 'click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        // Uncheck checkbox
        var checkboxId = e.target.parentElement.getAttribute("data-list-item");
        var checkbox = document.querySelector("#" + checkboxId);
        checkbox.checked = false;
        $(checkbox).trigger("change");
    });

    $search.unbind('focus', expandWidgetHandler);
    $search.on('focus', expandWidgetHandler);

    $search.unbind('keydown');
    $search.on('keydown', function(e) {
        var key = e.which || e.keyCode;
        switch (key) {
            case 38: // UP
            case 40: // DOWN
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
            case 13: // ENTER
                e.preventDefault();

                // Select the first (visible) item
                var firstItem = $available.find(".answer:not([hidden]) input").get(0);
                if (firstItem) {
                    $(firstItem).parent().trigger('click');
                }

                break;
        };
    });

    $search.unbind('keyup');
    $search.on('keyup', function() {
      var searchValue = $(this).val().toLowerCase();

      $fakeInput = $fakeInput || $('<span>').addClass('form-control-search').css('white-space', 'nowrap');
      $fakeInput.text(searchValue);
      $search.css('width', $fakeInput.insertAfter($search).width() + 70);
      $fakeInput.detach();

      // hide the answers that do not contain the searchvalue
      var anyHits = false;
      $.each($answers, function() {
        var labelValue = $(this).find('label')[0].innerHTML.toLowerCase();
        if (labelValue.indexOf(searchValue) === -1) {
            $(this).attr('hidden', '');
        } else {
            anyHits = true;
            $(this).removeAttr('hidden', '');
        }
      });

      if (anyHits) {
        $available.find(".has-noresults").attr('hidden', '');
      } else {
        $available.find(".has-noresults").removeAttr('hidden', '');
      }
    });

    $search.unbind('click');
    $search.on('click', function(e) {
        // Prevent bubbling the click event to the $widget (which expands/collapses the widget on click).
        e.stopPropagation();
    });
};

var setupSelectWidgets = function (context) {
    var $nodes = $('.select-widget', context);
    $nodes.each(function () {
        var multi = $(this).hasClass('multi');
        SelectWidget.call($(this), multi);
    });
};

var setupLessMoreWidgets = function (context) {
    var MAX_HEIGHT = 100;

    var convert = function () {
        var $ml = $(this);
        var column = $ml.data('column');
        var content = $ml.html();

        $ml.removeClass('transparent');

        // Element may be hidden (e.g. when rendering edit fields on record page).
        // Use jquery.actual plugin - possibly this can be removed in later
        // jquery versions
        if ($ml.actual('height') < MAX_HEIGHT) {
            return;
        }

        $ml.addClass('clipped');

        var $expandable = $('<div/>', {
            'class' : 'expandable popover column-content',
            'html'  : content
        });

        var toggleLabel = 'Show ' + column + ' &rarr;';

        var $expandToggle = $('<button/>', {
            'class' : 'btn btn-xs btn-primary trigger',
            'html'  : toggleLabel,
            'type'  : 'button',
            'aria-expanded' : false,
            'data-label-expanded' : 'Hide ' + column,
            'data-label-collapsed' : toggleLabel
        });

        $expandToggle.on('toggle', function (e, state) {
            var windowWidth = $(window).width();
            var leftOffset = $expandable.offset().left;
            var minWidth = 400;
            var colWidth = $ml.width();
            var newWidth = colWidth > minWidth ? colWidth : minWidth;
            if (state === 'expanded') {
                $expandable.css('width', newWidth + 'px');
                if (leftOffset + newWidth + 20 < windowWidth) {
                    return;
                }
                var overflow = windowWidth - (leftOffset + newWidth + 20);
                $expandable.css('left', (leftOffset + overflow) + 'px');
            }
        });

        $ml.empty()
           .append($expandToggle)
           .append($expandable);
    };

    var $widgets = $('.more-less', context);
    $widgets.each(convert);
};

// get the value from a field, depending on its type
var getFieldValues = function ($depends, filtered) {

    // If a field is not shown then treat it as a blank value (e.g. if fields
    // are in a hierarchy and the top one is not shown, or if the user does
    // not have write access to the field)
    if ($depends.length == 0 || $depends.css('display') == 'none') {
        return [''];
    }

    var type = $depends.data('column-type');

    var values = [];

    if (type === 'enum' || type === 'curval') {
        if (filtered) {
            var $visible = $depends.find('.select-widget .available .answer');
            $visible.each(function () {
                var item = $(this).find('[role="option"]');
                values.push(item.text());
            });
        } else {
            var $visible = $depends.find('.select-widget .current [data-list-item]:not([hidden])');
            $visible.each(function () {
                var item = $(this).hasClass("current__blank") ? "" : $(this).text();
                values.push(item)
            });
        }
    } else if (type === 'person') {
        values = [$depends.find('option:selected').text()];
    } else if (type === 'tree') {
        // get the hidden fields of the control - their textual value is located in a dat field
        $depends.find('.selected-tree-value').each(function() { values.push($(this).data('text-value')) });
    } else if (type === 'daterange') {
        var $f = $depends.find('.form-control');
        values = $f.map(function() {
            return $(this).val();
        }).get().join(' to ');
    } else {
        var $f = $depends.find('.form-control');
        values = [$f.val()];
    }

    // A multi-select field with no values selected should be the same as a
    // single-select with no values. Ensure that both are returned as a single
    // empty string value. This is important for display_condition testing, so
    // that at least one value is tested, even if it's empty
    if (values.length == 0) {
        values = [''];
    }

    return values;
};

var setupFileUpload = function (context) {
    var $nodes = $('.fileupload', context);
    $nodes.each(function () {
        var $el = $(this);
        var $ul = $el.find("ul");
        var url = $el.data("fileupload-url");
        var field = $el.data("field");
        var $progressBarContainer = $el.find('.progress-bar__container');
        var $progressBarProgress = $el.find('.progress-bar__progress');
        var $progressBarPercentage = $el.find('.progress-bar__percentage')

        $el.fileupload({
            dataType: 'json',
            url: url,
            paramName: "file",

            submit: function (e, data) {
                $progressBarContainer.css('display', 'block');
                $progressBarPercentage.html("0%");
                $progressBarProgress.css('width', '0%');
            },
            progress: function (e,data) {
                if (!$el.data("multivalue")) {
                    var $uploadProgression = Math.round(data.loaded / data.total * 10000)/100 + '%';
                    $progressBarPercentage.html($uploadProgression);
                    $progressBarProgress.css('width', $uploadProgression);
                }
            },
            progressall: function (e, data) {
                if ($el.data("multivalue")) {
                    var $uploadProgression = Math.round(data.loaded / data.total * 10000)/100 + '%';
                    $progressBarPercentage.html($uploadProgression);
                    $progressBarProgress.css('width', $uploadProgression);
                }

            },
            done: function (e, data) {
                if (!$el.data("multivalue")) {
                    $ul.empty();
                }
                var fileId = data.result.url.split("/").pop();
                var fileName = data.files[0].name;

                var $li = $('<li class="help-block"><input type="checkbox" name="' + field + '" value="' + fileId + '" aria-label="' + fileName + '" checked>Include file. Current file name: <a href="/file/' + fileId + '">' + fileName + '</a>.</li>');
                $ul.append($li);
            }
        });
    });
};

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
var setupDependentField = function () {

    var condition = this.condition;
    var rules     = this.rules;
    var $field    = this.field;

    // In order to hide the relevant fields, we used to trigger a change event
    // on all the fields they depended on. However, this doesn't work for
    // display fields that depend on a filval type field, as the values to
    // check are not rendered on the page until the relevant filtered curval
    // field is opened. As such, use the dependent-not-shown property instead,
    // which is evaluated server-side
    if ($field.data('dependent-not-shown')) {
        $field.hide();
    }

    var some = function (set, test) {
        for (var i = 0, j = set.length; i < j; i++) {
            if (test(set[i])) {
                return true;
            }
        }
        return false;
    };

    var test_all = function (condition, rules) {

        if (rules.length == 0) {
            return true;
        }

        var is_shown = false;

        rules.some(function(rule) { // Break if returns true

            var $depends    = rule.dependsOn;
            var regexp      = rule.regexp;
            var is_negative = rule.is_negative;

            var values = getFieldValues($depends, rule.filtered);
            var this_not_shown = is_negative ? false : true;
            $.each(values, function (index, value) {
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
                if (condition == 'OR') {
                    return is_shown; // Whether to break
                } else {
                    if (this_not_shown) {
                        is_shown = false;
                    }
                    return !is_shown; // Whether to break
                }
            }

            return false; // Continue loop

        });

        return is_shown;

    };

    rules.forEach(function(rule) {

        var $depends    = rule.dependsOn;
        var regexp      = rule.regexp;
        var is_negative = rule.is_negative;

        var processChange = function () {
            test_all(condition, rules) ? $field.show() : $field.hide();
            var $panel = $field.closest('.panel-group');
            if ($panel.length) {
                $panel.find('.linkspace-field').each(function() {
                    var none_shown = true; // Assume not showing panel
                    if ($(this).css('display') != 'none') {
                        $panel.show();
                        none_shown = false;
                        return false; // Shortcut checking any more fields
                    }
                    if (none_shown) { $panel.hide() } // Nothing matched
                });
            }

            // Trigger value check on any fields that depend on this one, e.g.
            // if this one is now hidden then that will change its value to
            // blank
            $field.trigger('change');
        };

        // If the field depended on is not actually in the form (e.g. if the
        // user doesn't have access to it) then treat it as an empty value and
        // process as normal. Process immediately as the value won't change
        if ($depends.length == 0) {
            processChange();
        }

        // Standard change of visible form field
        $depends.on('change', function (e) {
            processChange();
        });
    });


};

var setupDependentFields = function (context) {
    var fields = $('[data-has-dependency]', context).map(function () {
        var dependency  = $(this).data('dependency');
        var decoded    = JSON.parse(base64.decode(dependency));
        var rules      = decoded.rules;
        var condition  = decoded.condition;

        var rr = jQuery.map(rules, function(rule) {
            var match_type  = rule.operator;
            var is_negative = match_type.indexOf('not') !== -1 ? true : false;
            var regexp = match_type.indexOf('equal') !== -1
                ? (new RegExp("^" + rule.value + "$", 'i'))
                : (new RegExp(rule.value, 'i'));
            var id = rule.id;
            var filtered = false;
            if (rule.filtered) {
                id = rule.filtered;
                filtered = true;
            }
            return {
                dependsOn   : $('[data-column-id="' + id + '"]', context),
                regexp      : regexp,
                is_negative : is_negative,
                filtered    : filtered
            };
        });

        return {
            field     : $(this),
            condition : condition,
            rules     : rr
        };
    });

    fields.each(setupDependentField);
};

var setupTreeField = function () {
    var $this = $(this);
    var id = $this.data('column-id');
    var multiValue = $this.data('is-multivalue');
    var readOnly = $this.data('is-readonly');
    var $treeContainer = $this.find('.tree-widget-container');
    var field = $treeContainer.data('field');
    var layout_identifier = $('body').data('layout-identifier');
    var endNodeOnly = $treeContainer.data('end-node-only');
    var idsAsParams = $treeContainer.data('ids-as-params');
    var $treeFields = $this.find('[name="' + field + '"]');

    var treeConfig = {
        core: {
            check_callback : true,
            force_text : true,
            themes : { stripes : true },
            data : {
                url : function (node) {
                    return '/' + layout_identifier + '/tree' + new Date().getTime() + '/' + id + '?' + idsAsParams;
                },
                data : function (node) {
                    return { 'id' : node.id };
                }
            }
        },
        plugins : []
    };

    if (!multiValue) {
        treeConfig.core.multiple = false;
    } else {
        treeConfig.plugins.push('checkbox');
    }

    $treeContainer.on('changed.jstree', function (e, data) {
        // remove all existing hidden value fields
        $treeContainer.nextAll('.selected-tree-value').remove();
        var selectedElms = $treeContainer.jstree("get_selected", true);

        var values = [];

        $.each(selectedElms, function () {
            // store the selected values in hidden fields as children of the element
            var node = $('<input type="hidden" class="selected-tree-value" name="' + field + '" value="' + this.id + '" />').insertAfter($treeContainer);
            var text_value = data.instance.get_path(this, '#');
            node.data('text-value', text_value);
        });
        // Hacky: we need to submit at least an empty value if nothing is
        // selected, to ensure the forward/back functionality works. XXX If the
        // forward/back functionality is removed, this can be removed too.
        if (selectedElms.length == 0) {
            $treeContainer.after(
                '<input type="hidden" class="selected-tree-value" name="' + field + '" value="" />'
            );
        }

        $treeContainer.trigger('change');
    });

    $treeContainer.on('select_node.jstree', function (e, data) {
        if (data.node.children.length == 0) { return; }
        if (endNodeOnly) {
            $treeContainer.jstree(true).deselect_node(data.node);
            $treeContainer.jstree(true).toggle_node(data.node);
        } else if (multiValue) {
            $treeContainer.jstree(true).open_node(data.node);
        }
    });

    $treeContainer.jstree(treeConfig);

    // hack - see https://github.com/vakata/jstree/issues/1955
    $treeContainer.jstree(true).settings.checkbox.cascade = 'undetermined';

};

var setupTreeFields = function (context) {
    var $fields = $('[data-column-type="tree"]', context);
    $fields.filter(function () {
        return $(this).find('.tree-widget-container').length;
    }).each(setupTreeField);
};

var positionDisclosure = function (offsetTop, offsetLeft, triggerHeight) {
    var $disclosure = this;

    var left = (offsetLeft) + 'px';
    var top  = (offsetTop + triggerHeight ) + 'px';

    $disclosure.css({
        'left': left,
        'top' : top
    });

    // If the popover is outside the body move it a bit to the left
    if (document.body && document.body.clientWidth && $disclosure.get(0).getBoundingClientRect) {
        var windowOffset = document.body.clientWidth - $disclosure.get(0).getBoundingClientRect().right;
        if (windowOffset < 0) {
            $disclosure.css({
                'left': (offsetLeft + windowOffset) + 'px',
            });
        }
    }
};

var onDisclosureClick = function(e) {
    var $trigger = $(this);
    var currentlyPermanentExpanded = $trigger.hasClass('expanded--permanent');

    toggleDisclosure(e, $trigger, !currentlyPermanentExpanded, true);
}

var onDisclosureMouseover = function(e) {
    var $trigger = $(this);
    var currentlyExpanded = $trigger.attr('aria-expanded') === 'true';

    if (!currentlyExpanded) {
        toggleDisclosure(e, $trigger, true, false);
    }
}

var onDisclosureMouseout = function(e) {
    var $trigger = $(this);
    var currentlyExpanded = $trigger.attr('aria-expanded') === 'true';
    var currentlyPermanentExpanded = $trigger.hasClass('expanded--permanent');

    if (currentlyExpanded && !currentlyPermanentExpanded) {
        toggleDisclosure(e, $trigger, false, false);
    }
}

var toggleDisclosure = function (e, $trigger, state, permanent) {
    $trigger.attr('aria-expanded', state);
    $trigger.toggleClass('expanded--permanent', state && permanent);

    var expandedLabel = $trigger.data('label-expanded');
    var collapsedLabel = $trigger.data('label-collapsed');

    if (collapsedLabel && expandedLabel) {
        $trigger.html(state ? expandedLabel : collapsedLabel);
    }

    var $disclosure = $trigger.siblings('.expandable').first();
    $disclosure.toggleClass('expanded', state);

    if ($disclosure.hasClass('popover')) {
        var offset = $trigger.position();
        positionDisclosure.call(
            $disclosure, offset.top, offset.left, $trigger.outerHeight() + 6
        );
    }

    $trigger.trigger((state ? 'expand' : 'collapse'), $disclosure);

    // If this element is within another element that also has a handler, then
    // stop that second handler also doing its action. E.g. for a more-less
    // widget within a table row, do not action both the more-less widget and
    // the opening of a record by clicking on the row
    e.stopPropagation();
};


var setupDisclosureWidgets = function (context) {
    $('.trigger[aria-expanded]', context).on('click', onDisclosureClick);

    // Also show/hide disclosures on hover in the data-table
    $('.data-table .trigger[aria-expanded]', context).on('mouseover', onDisclosureMouseover);
    $('.data-table .trigger[aria-expanded]', context).on('mouseout', onDisclosureMouseout);
}

var runPageSpecificCode = function (context) {
    var page = $('body').data('page').match(/^(.*?)(:?\/\d+)?$/);
    if (page === null) { return; }

    var handler = Linkspace[page[1]];
    if (handler !== undefined) {
        handler(context);
    }
};

var setupHoverableTable = function(context) {
    $('.table tr[data-href]', context).on('click', function() {
        window.location = $(this).data("href");
    });
}

var confirmOnPageExit = function (e)
{
    e = e || window.event;
    var message = 'Please note that any changes will be lost.';
    if (e)
    {
        e.returnValue = message;
    }
    return message;
};

var setupClickToEdit = function(context) {
    $('.click-to-edit', context).on('click', function() {
        var $editToggleButton = $(this);
        this.innerHTML = this.innerHTML === "Edit" ? "View" : "Edit";
        $($editToggleButton.data('viewEl')).toggleClass('expanded');
        $($editToggleButton.data('editEl')).toggleClass('expanded');

        if (this.innerHTML === "View") { // If button is showing view then we are on edit page
            window.onbeforeunload = confirmOnPageExit;
        } else {
            window.onbeforeunload = null;
        }
    });
    $(".submit_button").click( function() {
        window.onbeforeunload = null;
    });
    $(".remove-unload-handler").click( function() {
        window.onbeforeunload = null;
    });
}

var setupSubmitListener = function(context) {
    $('.edit-form', context).on('submit', function(e) {
        var $button = $(document.activeElement);
        $button.prop('disabled', true);
        if ($button.prop("name")) {
            $button.after('<input type="hidden" name="' + $button.prop("name") + '" value="' + $button.val() + '" />');
        }
    });
}

var setupZebraTable = function(context) {
    $('.table--zebra', context).each(function(_, table) {
        var isOdd = true;
        $(table).children('tbody').children("tr:visible").each(function(_, tr) {
            $(tr).toggleClass("odd", isOdd);
            $(tr).toggleClass("even", !isOdd);
            isOdd = !isOdd;
        });
    });
}

// Used to hide and then display blank fields when viewing a record
var setupClickToViewBlank = function(context) {
    $('.click-to-view-blank', context).on('click', function() {
        var showBlankFields = this.innerHTML === "Show blank values";
        $('.click-to-view-blank-field', context).toggle(showBlankFields);
        this.innerHTML = showBlankFields ? "Hide blank values" : "Show blank values";
        setupZebraTable(context);
    });
}

var setFirstInputFocus = function(context) {
    $('.edit-form *:input[type!=hidden]:first', context).focus();
}

var setupRecordPopup = function(context) {
    $(".record-popup", context).on('click', function(e) {
        var record_id = $(this).data('record-id');
        var instance_id = $(this).data('instance-id');
        var m = $("#readmore_modal");
        var modal = m.find('.modal-body')
        modal.text('Loading...');
        modal.load('/record_body/' + record_id, null, function() {
            setupZebraTable(modal);
        });
        m.modal();
        // Stop the clicking of this pop-up modal causing the opening of the
        // overall record for edit in the data table
        event.stopPropagation();
    });
}

var setupAccessibility = function(context) {
    $("a[role=button]", context).on('keypress', function(e) {
        if (e.keyCode === 32) { // SPACE
            this.click();
        }
    });

    var $navbar = $(".navbar-fixed-bottom", context);
    if ($navbar.length) {
        $(".edit-form .form-group", context).on('focusin', function(e) {
            var $el = $(e.target);
            var elTop = $el.offset().top;
            var elBottom = elTop + $el.outerHeight();
            var navbarTop = $navbar.offset().top;
            if (elBottom > navbarTop) {
                $('html, body').animate({
                    scrollTop: $(window).scrollTop() + elBottom - navbarTop + 20
                }, 300);
            }
        });
    }
}
var getParams = function(options) {
    if (!options) { options = {} }; // IE11 compat
    return _.chain(location.search.slice(1).split('&'))
        .map(function (item) { if (item) { return item.split('='); } })
        .compact()
        .value()
        .filter(function(param) { return param[0] !== options.except});
}

var setupColumnFilters = function(context) {
    $(".column-filter", context).each(function() {
        var $columnFilter =  $(this);
        var colId =  $columnFilter.data("col-id");
        var autocompleteEndpoint = $columnFilter.data("autocomplete-endpoint");
        var autocompleteHasID = $columnFilter.data("autocomplete-has-id");
        var values = $columnFilter.data("values") || [];
        var $error = $columnFilter.find(".column-filter__error");
        var $searchInput = $columnFilter.find(".column-filter__search-input");
        var $clearSearchInput = $columnFilter.find(".column-filter__clear-search-input");
        var $spinner = $columnFilter.find(".column-filter__spinner");
        var $values = $columnFilter.find(".column-filter__values");
        var $submit = $columnFilter.find(".column-filter__submit");

        var searchQ = function() {
            return $searchInput.length ? $searchInput.val() : "";
        }

        var onEmptySearch = function() {
            $error.attr('hidden', '');
            renderValues();
        }

        var fetchValues = _.debounce(function() {
            var q = searchQ();
            if (!q.length) {
                onEmptySearch();
                return;
            }

            $error.attr('hidden', '');
            $spinner.removeAttr('hidden');

            $.getJSON(autocompleteEndpoint + q, function(data) {
                _.each(data, function(searchValue) {
                    if (autocompleteHasID) {
                        if (!_.some(values, function(value) {return value.id === searchValue.id.toString()})) {
                            values.push({
                                id: searchValue.id.toString(),
                                value: searchValue.name
                            });
                        }
                    } else {
                        values.push({ value: searchValue });
                    }
                });
            })
            .fail(function(jqXHR, textStatus, textError) {
                $error.text(textError);
                $error.removeAttr('hidden');
            })
            .always(function() {
                $spinner.attr('hidden', '');
                renderValues();
            });
        }, 250);

        // Values are sorted when we've got a search input field, so additional values
        // received from the API are sorted amongst currently available values.
        var sortValues = function() {
            return $searchInput.length === 1;
        }

        var renderValues = function() {
            var q = searchQ();
            $values.empty();
            var filteredValues = _.filter(values, function(value) {return value.value.toLowerCase().indexOf(q.toLowerCase()) > -1});
            var sortedAndFilteredValues = sortValues() ? _.sortBy(filteredValues, "value") : filteredValues;
            _.each(sortedAndFilteredValues, function(value, index) {
               $values.append(renderValue(value, index));
            });
        }

        var renderValue = function(value, index) {
            var uniquePrefix = 'column_filter_value_label_' + colId + '_' + index;
            return $('<li class="column-filter__value">' +
                '<label id="' + uniquePrefix + '_label" for="' + uniquePrefix + '">' +
                    '<input id="' + uniquePrefix + '" type="checkbox" value="' + value.id + '" ' + (value.checked ? "checked" : "") + ' aria-labelledby="' + uniquePrefix + '_label">' +
                    '<span role="option">' + value.value + '</span>' +
                '</label>' +
            '</li>');
        }

        $values.delegate("input", "change", function() {
            var checkboxValue = $(this).val();
            var valueIndex = _.findIndex(values, function(value) {return value.id === checkboxValue});
            values[valueIndex].checked = this.checked;
        });

        $searchInput.on("keyup", function() {
            var val = $(this).val();
            if (val.length) {
                $clearSearchInput.removeAttr('hidden');
            } else {
                $clearSearchInput.attr('hidden', '');
            }
        });

        var paramfull = function (param) {
            if (typeof param[1] === 'undefined') {
                return param[0];
            } else {
                return param[0] + "=" + param[1];
            }
        };
        if (autocompleteHasID) {
            $searchInput.on("keyup", fetchValues);

            $submit.on("click", function() {
                var selectedValues = _.map(_.filter(values, "checked"), "id");
                var params = getParams({except: "field" + colId});
                selectedValues.forEach(function(value) {
                    params.push(["field" + colId, value]);
                });
                window.location = "?" + params.map(function(param) { return paramfull(param); }).join("&");
            });
        } else {
            $searchInput.on('keypress', function(e) {
                // KeyCode Enter
                if (e.keyCode === 13) {
                    e.preventDefault();
                    $submit.trigger('click');
                }
            })

            $submit.on("click", function() {
                var params = getParams({except: "field" + colId});
                params.push(["field" + colId, searchQ()]);
                window.location = "?" + params.map(function(param) { return paramfull(param); }).join("&");
            });
        }

        $clearSearchInput.on("click", function(e) {
            e.preventDefault();
            $searchInput.val("");
            $clearSearchInput.attr('hidden', '');
            onEmptySearch();
        });

        renderValues();
    });
}

var handleHtmlEditorFileUpload = function(file, el) {
    if(file.type.includes('image')) {
        var data = new FormData();
        data.append('file', file);
        data.append('csrf_token', $('body').data('csrf-token'));
        $.ajax({
            url: '/file?ajax&is_independent',
            type: 'POST',
            contentType: false,
            cache: false,
            processData: false,
            dataType: 'JSON',
            data: data,
            success: function (response) {
                if(response.is_ok) {
                    $(el).summernote('editor.insertImage', response.url);
                } else {
                    console.log(response.error);
                }
            }
        })
        .fail(function(e) {
            console.log(e);
        });
    } else {
        console.log("The type of file uploaded was not an image");
    }
}

var setupHtmlEditor = function (context) {

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

    $('.summernote', context).summernote({
        dialogsInBody: true,
        height: 400,
        callbacks: {
            // Load initial content
            onInit: function() {
                var $sum_div = $(this);
                var $sum_input = $sum_div.siblings('input[type=hidden].summernote_content');
                $(this).summernote('code', $sum_input.val());
            },
            onImageUpload: function(files) {
                for(var i = 0; i < files.length; i++) {
                    handleHtmlEditorFileUpload(files[i], this);
                }
            },
            onChange: function (contents, $editable) {
                var $sum_div = $(this).closest('.summernote');
                // Ensure submitted content is empty string if blank content
                // (easier checking for blank values)
                if ($sum_div.summernote('isEmpty')) {
                    contents = '';
                }
                var $sum_input = $sum_div.siblings('input[type=hidden].summernote_content');
                $sum_input.val(contents);
            },
        }
    });

    // Only setup global logic on initial setup
    if (context !== undefined) {
        return;
    }
};

// Functions for graph plotting
function do_plot_json(plotData, options_in) {
    plotData = JSON.parse(plotData);
    options_in = JSON.parse(options_in);
    do_plot(plotData, options_in);
};
function do_plot (plotData, options_in) {
    var ticks = plotData.xlabels;
    var seriesDefaults;
    var plotOptions = {};
    var showmarker = (options_in.type == "line" ? true : false);
    plotOptions.highlighter =  {
        showMarker: showmarker,
        tooltipContentEditor: function(str, pointIndex, index, plot){
           return  plot._plotData[pointIndex][index][1];
        },
    };
    if (options_in.type == "bar") {
        plotOptions.seriesDefaults = {
            renderer:$.jqplot.BarRenderer,
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
            renderer:$.jqplot.DonutRenderer,
            rendererOptions: {
                sliceMargin: 3,
                showDataLabels: true,
                dataLabels: 'value',
                shadow: false
            }
        };
    } else if (options_in.type == "pie") {
        plotOptions.seriesDefaults = {
            renderer:$.jqplot.PieRenderer,
            rendererOptions: {
                showDataLabels: true,
                dataLabels: 'value',
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
                formatString: '%d%'
            };
        }
        plotOptions.axesDefaults = {
            tickRenderer: $.jqplot.CanvasAxisTickRenderer ,
            tickOptions: {
              angle: -30,
              fontSize: '8pt'
            }

        };
    }
    plotOptions.stackSeries = options_in.stackseries;
    plotOptions.legend = {
        renderer:$.jqplot.EnhancedLegendRenderer,
        show: options_in.showlegend,
        location: 'e',
        placement: 'outside'
    };
    $.jqplot('chartdiv' + options_in.id, plotData.points, plotOptions);
};

var setupGlobe = function (container) {

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

var setupTippy = function (context) {
    var tippyContext = context || document;
    tippy(tippyContext.querySelectorAll('.timeline-foreground'), {
        target: '.timeline-tippy',
        theme: 'light',
        onShown: function (e) {
            $('.moreinfo', context).off("click").on("click", function(e){
                var target = $( e.target );
                var record_id = target.data('record-id');
                var m = $("#readmore_modal");
                m.find('.modal-body').text('Loading...');
                m.find('.modal-body').load('/record_body/' + record_id);
                m.modal();
             });
        }
    });
};

// This function takes a color (hex) as the argument, calculates the color’s HSP value, and uses that
// to determine whether the color is light or dark.
// Source: https://awik.io/determine-color-bright-dark-using-javascript/
function lightOrDark(color) {
    // Convert it to HEX: http://gist.github.com/983661
    var hexColor = +("0x" + color.slice(1).replace(color.length < 5 && /./g, "$&$&"));
    var r = hexColor >> 16;
    var g = hexColor >> 8 & 255;
    var b = hexColor & 255;

    // HSP (Perceived brightness) equation from http://alienryderflex.com/hsp.html
    var hsp = Math.sqrt(
        0.299 * (r * r) +
        0.587 * (g * g) +
        0.114 * (b * b)
    );

    // Using the HSP value, determine whether the color is light or dark.
    // The source link suggests 127.5, but that seems a bit too low.
    if (hsp > 150) {
        return "light";
    } else {
        return "dark";
    }
}

// If the perceived background color is dark, switch the font color to white.
var injectContrastingColor = function(dataset) {
    dataset.forEach(function(entry) {
        if (entry.style && typeof(entry.style) === "string") {
            var backgroundColorMatch = entry.style.match(/background-color:\s(#[0-9A-Fa-f]{6})/);
            if (backgroundColorMatch && backgroundColorMatch[1]) {
                var backgroundColor = backgroundColorMatch[1];
                var backgroundColorLightOrDark = lightOrDark(backgroundColor);
                if (backgroundColorLightOrDark === "dark") {
                    entry.style = entry.style + ";" + " color: #FFFFFF";
                }
            }
        }
    });
}

var setupTimeline = function (container, options_in) {
    var records_base64 = container.data('records');
    var json = base64.decode(records_base64);
    var dataset = JSON.parse(json);
    injectContrastingColor(dataset);

    var items = new timeline.DataSet(dataset);
    var groups = container.data('groups');
    var json_group = base64.decode(groups);
    var groups = JSON.parse(json_group);
    var is_dashboard = container.data('dashboard') ? true : false;

    var layout_identifier = $('body').data('layout-identifier');

    // See http://visjs.org/docs/timeline/#Editing_Items
    var options = {
        margin: {
            item: {
                horizontal: -1
            }
        },
        moment: function (date) {
            return timeline.moment(date).utc();
        },
        clickToUse: is_dashboard,
        zoomFriction: 10,
        template: Handlebars.templates.timelineitem,
        orientation: {axis: "both"}
    };

    // Merge any additional options supplied
    for (var attrname in options_in) { options[attrname] = options_in[attrname]; }

    if (container.data('min')) {
        options.start = container.data('min');
    }
    if (container.data('max')) {
        options.end = container.data('max');
    }

    if (container.data('width')) {
        options.width = container.data('width');
    }
    if (container.data('height')) {
        options.width = container.data('height');
    }

    if (!container.data('rewind')) {
        options.editable = {
            add:         false,
            updateTime:  true,
            updateGroup: false,
            remove:      false
        };
        options.multiselect = true;
    }

    var tl = new timeline.Timeline(container.get(0), items, options);
    if (groups.length > 0) {
        tl.setGroups(groups);
    }

    // functionality to add new items on range change
    var persistent_max;
    var persistent_min;
    tl.on('rangechanged', function (props) {
        if (!props.byUser) {
            if (!persistent_min) { persistent_min = props.start.getTime(); }
            if (!persistent_max) { persistent_max = props.end.getTime(); }
            return;
        }

        // Shortcut - see if we actually need to continue with calculations
        if (props.start.getTime() > persistent_min && props.end.getTime() < persistent_max) {
            update_range_session(props);
            return;
        }
        container.prev('#loading-div').show();

        /* Calculate the range of the current items. This will min/max
            values for normal dates, but for dateranges we need to work
            out the dates of what was retrieved. E.g. the earliest
            end of a daterange will be the start of the range of
            the current items (otherwise it wouldn't have been
            retrieved)
        */

        // Get date range with earliest start
        var val = items.min('start');
        var min_start = val ? new Date(val.start) : undefined;
        // Get date range with latest start
        val = items.max('start');
        var max_start = val ? new Date(val.start) : undefined;
        // Get date range with earliest end
        val = items.min('end');
        var min_end = val ? new Date(val.end) : undefined;
        // If this is a date range without a time, then the range will have
        // automatically been altered to add an extra day to its range, in
        // order to show it across the expected period on the timeline (see
        // Timeline.pm). When working out the range to request, we have to
        // remove this extra day, as searching the database will not include it
        // and we will otherwise end up with duplicates being retrieved
        if (min_end && !val.has_time) {
            min_end.setDate(min_end.getDate()-1);
        }
        // Get date range with latest end
        val = items.max('end');
        var max_end = val ? new Date(val.end) : undefined;
        // Get earliest single date item
        val = items.min('single');
        var min_single = val ? new Date(val.single) : undefined;
        // Get latest single date item
        val = items.max('single');
        var max_single = val ? new Date(val.single) : undefined;

        // Now work out the actual range we have items for
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
        if (!have_range.min) {
            var from = props.start.getTime();
            var to = props.end.getTime();
            load_items(from, to);
        }
        if (props.start < have_range.min) {
            var from = props.start.getTime();
            var to = have_range.min.getTime();
            load_items(from, to, "to");
        }
        if (props.end > have_range.max) {
            var from = have_range.max.getTime();
            var to = props.end.getTime();
            load_items(from, to, "from");
        }
        if (!persistent_max || persistent_max < props.end.getTime()) {
            persistent_max = props.end.getTime();
        }
        if (!persistent_min || persistent_min > props.start.getTime()) {
            persistent_min = props.start.getTime();
        }

        container.prev('#loading-div').hide();

        // leave to end in case of problems rendering this range
        update_range_session(props);
    });
    var csrf_token = $('body').data('csrf-token');
    function update_range_session(props) {
        // Do not remember timeline range if adjusting timeline on dashboard
        if (!is_dashboard) {
            $.post({
                url: "/" + layout_identifier + "/data_timeline?",
                data: "from=" + props.start.getTime() + "&to=" + props.end.getTime() + "&csrf_token=" + csrf_token
            });
        }
    }

    function load_items(from, to, exclusive) {
        /* we use the exclusive parameter to not include ranges
            that go over that date, otherwise we will retrieve
            items that we already have */
        var url = "/" + layout_identifier + "/data_timeline/" + "10" + "?from=" + from + "&to=" + to + "&exclusive=" + exclusive;
        if (is_dashboard) {
            url = url + '&dashboard=1&view=' + container.data('view');
        }
        $.ajax({
            async: false,
            url: url,
            dataType:'json',
            success: function(data) {
                items.add(data);
            }
        });
    }

    return tl;
};

var setupOtherUserViews = function (context) {

    var layout_identifier = $('body').data('layout-identifier');
    $("#views_other_user_typeahead").typeahead({
        delay: 500,
        matcher: function () { return true; },
        sorter: function (items) { return items; },
        afterSelect: function (selected) {
            $("#views_other_user_id").val(selected.id);
        },
        source: function (query, process) {
            return $.ajax({
                type: 'GET',
                url: '/' + layout_identifier + '/match/user/',
                data: { q: query },
                success: function(result) { process(result) },
                dataType: 'json'
            });
        }
    });
};

var setupDataTables = function (context) {

    $('.dtable', context).each(function () {
        var pagelength = $(this).data('page-length') || 10;
        console.log(pagelength);
        $(this).dataTable({
            order: [
                [ 1, 'asc' ]
            ],
            pageLength: pagelength
        });
    });

};

var Linkspace = {
    constants: {
        ARROW_LEFT: 37,
        ARROW_RIGHT: 39
    },

    init: function (context) {
        setupLessMoreWidgets(context);
        setupDisclosureWidgets(context);
        setupSelectWidgets(context);
        setupFileUpload(context);
        runPageSpecificCode(context);
        setupSubmitListener(context);
        setFirstInputFocus(context);
        setupRecordPopup(context);
        setupAccessibility(context);
        setupColumnFilters(context);
        setupHtmlEditor(context);
    },

    debug: function (msg) {
        if (typeof(console) !== 'undefined' && console.debug) {
            console.debug('[LINKSPACE]', msg);
        }
    },

    TabPanel: function () {
        var $this = $(this);
        var $tabs = $this.find('[role="tab"]');
        var $panels = $this.find('[role="tabpanel"]');

        var indexedTabs = [];

        $tabs.each(function (i) {
            indexedTabs[i] = $(this);
            $(this).data('index', i);
        });

        var selectTab = function (e) {
            if (e) {
                e.preventDefault();
            }

            var $thisTab = $(this);

            if ($thisTab.attr('aria-selected') === 'true') { return false; }

            var $thisPanel = $panels.filter($thisTab.attr('href'));

            var $activeTab = $tabs.filter('[aria-selected="true"]');
            var $activePanel = $panels.filter('.active');

            $activeTab.attr('aria-selected', false);
            $activePanel.removeClass('active');

            $thisTab.attr('aria-selected', true);
            $thisPanel.addClass('active');

            $thisTab.attr('tabindex', '0');
            $tabs.filter('[aria-selected="false"]').attr('tabindex', '-1');

            return false;
        };

        var moveTab = function (e) {
            var $thisTab = $(this);
            var index = $thisTab.data('index');
            var k = e.keyCode;
            var left = Linkspace.constants.ARROW_LEFT, right = Linkspace.constants.ARROW_RIGHT;
            if ([left, right].indexOf(k) < 0) { return; }
            var $nextTab;
            if (
                (k === left  && ($nextTab = indexedTabs[index-1])) ||
                (k === right && ($nextTab = indexedTabs[index+1]))
            ) {
                selectTab.call($nextTab);
                $nextTab.focus();
            }
        };

        $tabs.on('click', selectTab);
        $tabs.on('keyup', moveTab);
        $tabs.filter('[aria-selected="false"]').attr('tabindex', '-1');
    }
};

Linkspace.edit = function (context) {
    Linkspace.debug('Record edit JS firing');
    setupTreeFields(context);
    setupDependentFields(context);
    setupClickToEdit(context);
    setupClickToViewBlank(context);
    setupCalculator(context);
    setupZebraTable(context);
}

Linkspace.config = function () {
    setupHtmlEditor();
}

Linkspace.system = function () {
    setupHtmlEditor();
}

Linkspace.data_timeline = function () {

    var save_elem_sel    = '#submit_button',
        cancel_elem_sel  = '#cancel_button',
        changed_elem_sel = '#visualization_changes',
        hidden_input_sel = '#changed_data';

    var changed = {};

    function on_move (item, callback) {
        changed[item.id] = item;

        var save_button = $( save_elem_sel );
        if ( save_button.is(':hidden') ) {
            $(window).bind('beforeunload', function(e) {
                var error_msg = 'If you leave this page your changes will be lost.';
                if (e) {
                    e.returnValue = error_msg;
                }
                return error_msg;
            });

            save_button.closest('form').css('display', 'block');
        }

        var changed_item = $('<li>' + item.content + '</li>');
        $( changed_elem_sel ).append(changed_item);

        return callback(item);
    }

    function snap_to_day (datetime, scale, step) {
        // A bit of a mess, as the input to this function is in the browser's
        // local timezone, but we need to return it from the function in UTC.
        // Pull the UTC values from the local date, and then construct a new
        // moment using those values.
        var year = datetime.getUTCFullYear();
        var month = ("0" + (datetime.getUTCMonth() + 1)).slice(-2);
        var day = ("0" + datetime.getUTCDate()).slice(-2);
        return timeline.moment.utc('' + year + month + day);
    }

    var options = {
        onMove:   on_move,
        snap:     snap_to_day,
    };

    var tl = setupTimeline($('.visualization'), options);

    function before_submit (e) {
        var submit_data = _.mapObject( changed,
            function( val, key ) {
                return {
                    column: val.column,
                    current_id: val.current_id,
                    from: val.start.getTime(),
                    to:   (val.end || val.start).getTime()
                };
            }
        );
        $(window).off('beforeunload');

        // Store the data as JSON on the form
        var submit_json = JSON.stringify(submit_data);
        var data_field = $(hidden_input_sel);
        data_field.attr('value', submit_json );
    }

    // Set up form button behaviour
    $( save_elem_sel ).bind( 'click', before_submit );
    $( cancel_elem_sel ).bind( 'click', function (e) {
        $(window).off('beforeunload');
    });

    var layout_identifier = $('body').data('layout-identifier');

    function on_select (properties) {
        var items = properties.items;
        if (items.length == 0) {
            $('.bulk_href').on('click', function(e) {
                e.preventDefault();
                alert("Please select some records on the timeline first");
                return false;
            });
        } else {
            var hrefs = [];
            $("#delete_ids").empty();
            properties.items.forEach(function(item) {
                var id = item.replace(/\+.*/, '');
                hrefs.push("id=" + id);
                $("#delete_ids").append('<input type="hidden" name="delete_id" value="' + id + '">');
            });
            var href = hrefs.join('&');
            $('#update_href').attr("href", "/" + layout_identifier + "/bulk/update/?" + href);
            $('#clone_href').attr("href", "/" + layout_identifier + "/bulk/clone/?" + href);
            $('#count_delete').text(items.length);
            $('.bulk_href').off();
        }
    }

    tl.on('select', on_select);
    on_select({ items: [] });

    setupTippy();

    setupOtherUserViews();
}

Linkspace.data_graph = function () {
    setupOtherUserViews();
}

Linkspace.data_table = function () {
    setupHoverableTable();
    setupOtherUserViews();

    $('#modal_sendemail').on('show.bs.modal', function (event) {
        var button = $(event.relatedTarget);
        var peopcol_id = button.data('peopcol_id');
        $('#modal_sendemail_peopcol_id').val(peopcol_id);
    });

    $("#data-table").floatThead({
        floatContainerCss: {},
        zIndex: function($table){
            return 999;
        },
        ariaLabel: function($table, $headerCell, columnIndex) {
            return $headerCell.data('thlabel');
        }
    });

    if (!FontDetect.isFontLoaded('14px/1 FontAwesome')) {
        $( ".use-icon-font" ).hide();
        $( ".use-icon-png" ).show();
    }
}

Linkspace.data_globe = function () {
    $('.globe').each(function () {
        setupGlobe($(this));
    });
    setupOtherUserViews();
}

Linkspace.data_calendar = function () {
    setupOtherUserViews();
}

Linkspace.purge = function () {
    $('#selectall').click(function() {
        $('.record_selected').prop('checked', this.checked);
    });
};

Linkspace.metric = function () {
    $('#modal_metric').on('show.bs.modal', function (event) {
        var button = $(event.relatedTarget);
        var metric_id = button.data('metric_id');
        $('#metric_id').val(metric_id);
        if (metric_id) {
            $('#delete_metric').show();
        } else {
            $('#delete_metric').hide();
        }
        var target_value = button.data('target_value');
        $('#target_value').val(target_value);
        var x_axis_value = button.data('x_axis_value');
        $('#x_axis_value').val(x_axis_value);
        var y_axis_grouping_value = button.data('y_axis_grouping_value');
        $('#y_axis_grouping_value').val(y_axis_grouping_value);
    });
};

Linkspace.graphs = function (context) {
    setupDataTables(context);
    // When a search is entered in a datatables table, selected graphs that are
    // filtered will not be submitted. Therefore, find all selected values and
    // add them to the form
    $('#submit').on('click', function(e){
        var t = $('.dtable').DataTable().column(0).nodes().to$().each(function() {
            var $cell = $(this);
            var $checkbox = $cell.find('input');
            if ($checkbox.is(':checked')) {
                $('<input type="hidden" name="graphs">').val($checkbox.val()).appendTo('form');
            }
        });
    });

};

Linkspace.graph = function (context) {

    $('#is_shared').change(function () {
        $('#group_id_div').toggle(this.checked);
    }).change();
    $('.date-grouping').change(function () {
        if ($('#trend').val() || $('#set_x_axis').find(':selected').data('is-date')) {
            $('#x_axis_date_display').show();
        } else {
            $('#x_axis_date_display').hide();
        }
    }).change();
    $('#trend').change(function () {
        if ($(this).val()) {
            $('#group_by_div').hide();
        } else {
            $('#group_by_div').show();
        }
    }).change();
    $('#x_axis_range').change(function () {
        if ($(this).val() == "custom") {
            $('#custom_range').show();
        } else {
            $('#custom_range').hide();
        }
    }).change();
    $('#y_axis_stack').change(function () {
        if ($(this).val() == "sum") {
            $('#y_axis_div').show();
        } else {
            $('#y_axis_div').hide();
        }
    }).change();
}

Linkspace.user = function (context) {
    setupDataTables(context);

    $(document).on("click", ".cloneme", function() {
        var parent = $(this).parents('.limit-to-view');
        var cloned = parent.clone();
        cloned.removeAttr('id').insertAfter(parent);
    });
    $(document).on("click", ".removeme", function() {
        var parent = $(this).parents('.limit-to-view');
        if (parent.siblings(".limit-to-view").length > 0) {
            parent.remove();
        }
    });

};

Linkspace.layout = function (context) {
    $('.tab-interface').each(Linkspace.TabPanel);

    var $config = $('#permission-configuration');
    var $rule = $('.permission-rule', context);

    var $ruleTemplate = $('#permission-rule-template');
    var $cancelRuleButton = $rule.find('button.cancel-permission');
    var $addRuleButton = $rule.find('button.add-permission');

    var closePermissionConfig = function () {
        $config.find('input').each(function () {
            $(this).prop('checked', false);
        });
        $config.attr('hidden', '');
        $('#configure-permissions').removeAttr('hidden').focus();
    };

    var handlePermissionChange = function () {
        var $permission = $(this);
        var groupId = $permission.data('group-id');

        var $editButton   = $permission.find('button.edit');
        var $deleteButton = $permission.find('button.delete');
        var $okButton     = $permission.find('button.ok');

        $permission.find('input').on('change', function () {
            var pClass = 'permission-' + $(this).data('permission-class');
            var checked = $(this).prop('checked');
            $permission.toggleClass(pClass, checked);

            if (checked) { return; }

            $(this).siblings('div').find('input').each(function () {
                $(this).prop(checked);
                pClass = 'permission-' + $(this).data('permission-class');
                $permission.toggleClass(pClass, checked);
            });
        });

        $editButton.on('expand', function (event) {
            $permission.addClass('edit');
            $permission.find('.group-name').focus();
        });

        $deleteButton.on('click', function (event) {
            $('#permissions').removeClass('permission-group-' + groupId);
            $permission.remove();
        });

        $okButton.on('click', function (event) {
            $permission.removeClass('edit');
            $okButton.parent().removeClass('expanded');
            $editButton.attr('aria-expanded', false).focus();
        });
    };

    $cancelRuleButton.on('click', closePermissionConfig);

    $addRuleButton.on('click', function () {
        var $newRule = $($ruleTemplate.html());
        var $currentPermissions = $('#current-permissions ul');
        var $selectedGroup = $config.find('option:selected');

        var groupId = $selectedGroup.val();

        $config.find('input').each(function () {
            var $input = $(this);
            var state = $input.prop('checked');

            if (state) {
                $newRule.addClass(
                    'permission-' +
                    $input.data('permission-class').replace(/_/g,'-')
                );
            }

            $newRule.find('input#' + $input.attr('id'))
                .prop('checked', state)
                .attr('id', $input.attr('id') + groupId)
                .attr('name', $input.attr('name') + groupId)
                .next('label').attr('for', $input.attr('id'));
        });

        $newRule.appendTo($currentPermissions);
        $newRule.attr('data-group-id', groupId);

        $('#permissions').addClass('permission-group-' + groupId);
        $newRule.find('.group-name').text($selectedGroup.text());

        $newRule.find('button.edit').on('click', onDisclosureClick);

        handlePermissionChange.call($newRule);
        closePermissionConfig();
    });

    $('#configure-permissions').on('click', function () {
        var $permissions = $('#permissions');
        var selected = false;
        $('#permission-configuration').find('option').each(function () {
            var $option = $(this);
            $option.removeAttr('disabled');
            if ($permissions.hasClass('permission-group-' + $option.val())) {
                $option.attr('disabled', '');
            } else {
                // make sure the first non-disabled option gets selected
                if (!selected) {
                    $option.attr('selected', '');
                    selected = true;
                }
            }
        });
        $(this).attr('hidden', '');
        $('#permission-configuration').removeAttr('hidden');

        $(this).parent().find('h4').focus();
    });

    $('#current-permissions .permission').each(handlePermissionChange);
};

Linkspace.index = function (context) {
    $(document).ready(function () {
        $('.dashboard-graph', context).each(function () {
            var graph = $(this);
            var graph_data = base64.decode(graph.data('plot-data'));
            var options_in = base64.decode(graph.data('plot-options'));
            do_plot_json(graph_data, options_in);
        });
        $('.visualization', context).each(function () {
            setupTimeline($(this), {});
        });
        $('.globe', context).each(function () {
            setupGlobe($(this));
        });
        setupTippy(context);
    });
}

Linkspace.init();
