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
    var $container = $('main');
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
        return $('<li ' + (checked ? '' : 'hidden') + ' data-list-item="' + valueId + '" class="' + className + '">' + label + '</li>');
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
        if (!$.isArray(filterFields)) {
            if (typeof(console) !== 'undefined' && console.error) {
                console.error("Invalid data-filter-fields found. It should be a proper JSON array of fields.");
            }
        }

        var currentValues = $available.find("input:checked").map(function() { return parseInt($(this).val()); }).get();

        // Collect values of linked fields
        var values = [];
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
        if (!$selectWidget.find(newlyFocussedElement).length && newlyFocussedElement && !$(newlyFocussedElement).is(".modal, .page, .col-md-12")) {
            collapse($widget, $trigger, $target);
        }
    }

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

        if ($ml.height() < MAX_HEIGHT) {
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
var getFieldValues = function ($depends) {

    // If a field is not shown then treat it as a blank value (e.g. if fields
    // are in a hierarchy and the top one is not shown
    if ($depends.css('display') == 'none') {
        return '';
    }

    var type = $depends.data('column-type');

    if (type === 'enum' || type === 'curval') {
        var $visible = $depends.find('.select-widget .current [data-list-item]:not([hidden])');
        var items = [];
        $visible.each(function () {
            var item = $(this).hasClass("current__blank") ? "" : $(this).text();
            items.push(item)
        });
        return items;
    } else if (type === 'person') {
        return [$depends.find('option:selected').text()];
    } else if (type === 'tree') {
        // get the hidden fields of the control - their textual value is located in a dat field
        var items = [];
        $depends.find('.selected-tree-value').each(function() { items.push($(this).data('text-value')) });
        return items;
    } else if (type === 'daterange') {
        var $f = $depends.find('.form-control');
        var dates = $f.map(function() {
            return $(this).val();
        }).get().join(' to ');
        return [dates];
    } else {
        var $f = $depends.find('.form-control');
        return [$f.val()];
    }
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

        var is_shown = condition == 'AND' ? true : false;

        rules.forEach(function(rule) {

            var $depends    = rule.dependsOn;
            var regexp      = rule.regexp;
            var is_negative = rule.is_negative;

            var values = getFieldValues($depends);
            var this_shown = some(values, function (value) {
                return is_negative ? !regexp.test(value) : regexp.test(value)
            });

            if (this_shown == true && condition == 'OR') {
                is_shown = true;
            }
            if (this_shown == false && condition == 'AND') {
                is_shown = false;
            }

        });

        return is_shown;

    };

    rules.forEach(function(rule) {

        var $depends    = rule.dependsOn;
        var regexp      = rule.regexp;
        var is_negative = rule.is_negative;


        $depends.on('change', function (e) {
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
        });

        // trigger a change to toggle all dependencies
        $depends.trigger('change');
    });


};

var setupDependentFields = function (context) {
    var fields = $('[data-has-dependency]').map(function () {
        var dependency  = $(this).data('dependency');
        var decoded    = JSON.parse(base64.decode(dependency));
        var rules      = decoded.rules;
        var condition  = decoded.condition;

        var rr = jQuery.map(rules, function(rule) {
            var match_type  = rule.operator;
            var is_negative = match_type.indexOf('not') !== -1 ? true : false;
            var regexp = match_type.search('equal') == 0
                ? (new RegExp("^" + rule.value + "$"))
                : (new RegExp(rule.value));
            return {
                dependsOn   : $('[data-column-id="' + rule.id + '"]'),
                regexp      : regexp,
                is_negative : is_negative
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
};

var toggleDisclosure = function () {
    var $trigger = $(this);
    var $disclosure = $trigger.siblings('.expandable').first();

    var offset = $trigger.position();

    if ($disclosure.hasClass('popover')) {
        positionDisclosure.call(
            $disclosure, offset.top, offset.left, $trigger.height()
        );
    }

    var currentlyExpanded = $trigger.attr('aria-expanded') === 'true';
    $trigger.attr('aria-expanded', !currentlyExpanded);

    var expandedLabel = $trigger.data('label-expanded');
    var collapsedLabel = $trigger.data('label-collapsed');

    if (collapsedLabel && expandedLabel) {
        $trigger.html(currentlyExpanded ? collapsedLabel : expandedLabel);
    }

    $disclosure.toggleClass('expanded', !currentlyExpanded);

    $trigger.trigger((currentlyExpanded ? 'collapse' : 'expand'), $disclosure);
};

var setupDisclosureWidgets = function (context) {
    $('.trigger[aria-expanded]', context).on('click', toggleDisclosure);
}

var runPageSpecificCode = function (context) {
    var page = $('body').data('page').match(/^(.*?)(:?\/\d+)?$/);
    if (page === null) { return; }

    var handler = Linkspace[page[1]];
    if (handler !== undefined) {
        handler(context);
    }
};

var setupClickToEdit = function(context) {
    $('.click-to-edit', context).on('click', function() {
        var $editToggleButton = $(this);

        // Open and hide expanded element
        toggleDisclosure.bind($editToggleButton).call();

        $editToggleButton.siblings('.topic-click-to-edit-fields').hide();
        $editToggleButton.hide();
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

// Used to hide and then display blank fields when viewing a record
var setupClickToViewBlank = function() {
    $('.click-to-view-blank').on('click', function() {
        var $viewToggleButton = $(this);
        $('.click-to-view-blank-field').show();
        $viewToggleButton.hide();
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
        m.find('.modal-body').text('Loading...');
        m.find('.modal-body').load('/record_body/' + record_id);
        m.modal();
    });
    // Stop the clicking of more-less buttons within the record details popping
    // up the more-less box and the record modal
    $(".record-popup .more-less").click(function(event){
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

    $('.summernote').summernote({
        height: 400,
        callbacks: {
            onImageUpload: function(files) {
                for(var i = 0; i < files.length; i++) {
                    upload_file(files[i], this);
                }
            }
        }
    });
    $('#homepage_text_sn').summernote('code', $('#homepage_text').val());
    $('#homepage_text2_sn').summernote('code', $('#homepage_text2').val());
    $('#update').click(function(){
        if ($('#homepage_text_sn').summernote('isEmpty')) {
            var content = '';
        } else {
            var content = $('#homepage_text_sn').summernote('code');
        }
        $('#homepage_text').val(content);
        if ($('#homepage_text2_sn').summernote('isEmpty')) {
            content = '';
        } else {
            content = $('#homepage_text2_sn').summernote('code');
        }
        $('#homepage_text2').val(content);
    });
    function upload_file(file, el) {
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
};

var setupTimeline = function (context) {

    var container = $('#visualization');

    var records_base64 = container.data('records');
    var json = base64.decode(records_base64);
    var items = new timeline.DataSet(JSON.parse(json));
    var groups = container.data('groups');
    var json_group = base64.decode(groups);
    var groups = JSON.parse(json_group);
    var changed = {};

    var template = Handlebars.templates.timelineitem;

    var save_elem_sel    = '#submit_button',
        cancel_elem_sel  = '#cancel_button',
        changed_elem_sel = '#visualization_changes',
        hidden_input_sel = '#changed_data';

    function before_submit (e) {
        var submit_data = _.mapObject( changed,
            function( val, key ) {
                return {
                    column: val.column,
                    current_id: val.current_id,
                    from: val.start.toISOString().substring(0, 10),
                    to:   (val.end || val.start).toISOString().substring(0, 10)
                };
            }
        );
        $(window).off('beforeunload');

        // Store the data as JSON on the form
        var submit_json = JSON.stringify(submit_data);
        var data_field = $(hidden_input_sel);
        data_field.attr('value', submit_json );
    }

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

        var changed_item = $('<li>' + item.title + '</li>');
        $( changed_elem_sel ).append(changed_item);

        return callback(item);
    }

    function snap_to_day (datetime, scale, step) {
        return new Date (
            datetime.getFullYear(),
            datetime.getMonth(),
            datetime.getDate()
        );
    }

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

    // Set up form button behaviour
    $( save_elem_sel ).bind( 'click', before_submit );
    $( cancel_elem_sel ).bind( 'click', function (e) {
        $(window).off('beforeunload');
    });

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
        onMove:   on_move,
        zoomFriction: 10,
        snap:     snap_to_day,
        template: template,
        orientation: {axis: "both"}
    };

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
    tl.on('select', on_select);
    on_select({ items: [] });

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
        $('#loading-div').show();

        /* Calculate the range of the current items. This will min/max
            values for normal dates, but for dateranges we need to work
            out the dates of what was retrieved. E.g. the earliest
            end of a daterange will be the start of the range of
            the current items (otherwise it wouldn't have been
            retrieved)
        */
        var val = items.min('start');
        var min_start = val ? new Date(val.start) : undefined;
        val = items.max('start');
        var max_start = val ? new Date(val.start) : undefined;
        val = items.min('end');
        var min_end = val ? new Date(val.end) : undefined;
        val = items.max('end');
        var max_end = val ? new Date(val.end) : undefined;
        val = items.min('single');
        var min_single = val ? new Date(val.single) : undefined;
        val = items.max('single');
        var max_single = val ? new Date(val.single) : undefined;
        var have_range = {};
        if (min_end && min_single) {
            have_range.min = min_end < min_single ? min_end : min_single;
        } else {
            have_range.min = min_end || min_single;
        }
        if (max_start && max_single) {
            have_range.max = max_start > max_single ? max_start : max_single;
        } else {
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

        $('#loading-div').hide();

        // leave to end in case of problems rendering this range
        update_range_session(props);
    });
    var csrf_token = $('body').data('csrf-token');
    function update_range_session(props) {
        $.post({
            url: "/" + layout_identifier + "/data_timeline",
            data: "from=" + props.start.getTime() + "&to=" + props.end.getTime() + "&csrf_token=" + csrf_token
        });
    }

    function load_items(from, to, exclusive) {
        $.ajax({
            async: false,
            /* we use the exclusive parameter to not include ranges
                that go over that date, otherwise we will retrieve
                items that we already have */
            url: "/" + layout_identifier + "/data_timeline/" + "10" + "?from=" + from + "&to=" + to + "&exclusive=" + exclusive,
            dataType:'json',
            success: function(data) {
                items.add(data);
            }
        });
    }

    tippy('.timeline-foreground', {
        target: '.timeline-tippy',
        theme: 'light',
        onShown: function (e) {
            $('.moreinfo').off("click").on("click", function(e){
                var target = $( e.target );
                var record_id = target.data('record-id');
                var m = $("#readmore_modal");
                m.find('.modal-body').text('Loading...');
                m.find('.modal-body').load('/record_body/' + record_id);
                m.modal();
             });
        }
    });

}

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
}

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
}

Linkspace.record = function () {
    setupClickToViewBlank();
}

Linkspace.config = function () {
    setupHtmlEditor();
}

Linkspace.system = function () {
    setupHtmlEditor();
}

Linkspace.data_timeline = function () {
    setupTimeline();
    setupOtherUserViews();
}

Linkspace.data_graph = function () {
    setupOtherUserViews();
}

Linkspace.data_table = function () {
    setupOtherUserViews();
}

Linkspace.data_globe = function () {
    setupOtherUserViews();
}

Linkspace.data_calendar = function () {
    setupOtherUserViews();
}

Linkspace.layout = function () {
    $('.tab-interface').each(Linkspace.TabPanel);

    var $config = $('#permission-configuration');
    var $rule = $('.permission-rule');

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

        $newRule.find('button.edit').on('click', toggleDisclosure);

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

Linkspace.init();
