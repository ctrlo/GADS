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
    if ($widget.hasClass("hasSelectWidget")) {
        return;
    }

    var isSingle = this.hasClass('single');
    var $container = $('main');
    var $trigger = $widget.find('[aria-expanded]');
    var $current = this.find('.current');
    var $available = this.find('.available');
    var $availableItems = this.find('.available .answer input');
    var $target  = this.find('#' + $trigger.attr('aria-controls'));
    var $currentItems = $current.children();
    var $answers = this.find('.answer');
    var $search = this.find('.form-control-search');
    var $clearSearch = this.find('.form-control-search__clear');
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
            $associated.on('change', function (e) {
                e.stopPropagation();
                if ($(this).prop('checked')) {
                    $item.removeAttr('hidden');
                } else {
                    $item.attr('hidden', '');
                }
                update();
            });
        };
    };

    var connectSingle = function () {
        $currentItems.each(function(_, item) {
            var $item = $(item);
            var itemId = $item.data('list-item');
            var $associated = $('#' + itemId);

            $associated.on('click', function(e){
                e.stopPropagation();
            });

            $associated.parent().keypress(function(e) {
                // KeyCode Spacebar
                if(e.keyCode === 32) {
                    $(this).trigger('click');
                }
            })

            $associated.parent().on('click', function(e){
                e.stopPropagation();
                $currentItems.each(function () {
                    $(this).attr('hidden', '');
                });

                $current.toggleClass('empty', false);
                $item.removeAttr('hidden');

                $widget.trigger('change');
                onTriggerClick($widget, $trigger, $target)();
            });
        });
    };

    var currentLi = function(multi, field, value, label, checked) {
        if (multi && !value) {
            return $('<li class="none-selected">blank</li>');
        }

        var valueId = value ? field + "_" + value : field + "__blank";
        return $('<li ' + (checked ? '' : 'hidden') + ' data-list-item="' + valueId + '" class="current">' + label + '</li>');
    }

    var availableLi = function(multi, field, value, label, checked) {
        if (multi && !value) {
            return null;
        }

        var valueId = value ? field + "_" + value : field + "__blank";
        var classNames = value ? "answer" : "answer answer--blank";

        var detailsButton = '<span class="details">' +
            '<button type="button" class="more-info" data-record-id="' + value + '" aria-describedby="' + valueId + '_label">' +
                'Details' +
            '</button>' +
        '</span>';

        return $('<li class="' + classNames + '">' +
            '<span class="control">' +
                '<label id="' + valueId + '_label" for="' + valueId + '">' +
                    '<input id="' + valueId + '" type="' + (multi ? "checkbox" : "radio") + '" name="' + field + '" ' + (checked ? 'checked' : '') + ' value="' + value + '" class="' + (multi ? "" : "visually-hidden") + '">' +
                    '<span>' + label + '</span>' +
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
            $current.empty();

            if (data.error === 0) {
                var checked = currentValues.includes(NaN);
                $current.append(currentLi(multi, field, null, "blank", checked));
                $available.append(availableLi(multi, field, null, 'blank', checked));

                $.each(data.records, function(recordIndex, record) {
                    var checked = currentValues.includes(record.id);
                    $current.append(currentLi(multi, field, record.id, record.label, checked));
                    $available.append(availableLi(multi, field, record.id, record.label, checked));
                });

                $currentItems = $current.children();
                $available = $selectWidget.find('.available');
                $availableItems = $selectWidget.find('.available .answer input');
                updateState();
                connect();

                lastFetchParams = fetchParams;
            } else {
                var errorMessage = data.error === 1 ? data.message : "Oops! Something went wrong.";
                var errorLi = $('<li class="answer answer--blank alert alert-danger"><span class="control"><label>' + errorMessage + '</label></span></li>');
                $available.append(errorLi);
            }
        })
        .fail(function() {
            var errorMessage = data.error === 1 ? data.message : "Oops! Something went wrong.";
            var errorLi = $('<li class="answer answer--blank alert alert-danger"><span class="control"><label>' + errorMessage + '</label></span></li>');
            $available.append(errorLi);
        })
        .always(function() {
            $available.find(".spinner").attr('hidden', '');
        });
    }

    var onTriggerClick = function ($widget, $trigger, $target) {
        return function (event) {
            var isCurrentlyExpanded = $trigger.attr('aria-expanded') === 'true';
            var willExpandNext = !isCurrentlyExpanded;

            $trigger.attr('aria-expanded', willExpandNext);

            if (willExpandNext) {
                if ($selectWidget.data("filter-endpoint") && $selectWidget.data("filter-endpoint").length) {
                    fetchOptions();
                }

                var widgetTop = $widget.offset().top;
                var widgetBottom = widgetTop + $widget.outerHeight();
                var viewportTop = $(window).scrollTop();
                var viewportBottom = viewportTop + $(window).height();
                var minimumRequiredSpace = 200;
                var fitsBelow = widgetBottom + minimumRequiredSpace < viewportBottom;
                var fitsAbove = widgetTop - minimumRequiredSpace > viewportTop;
                var expandAtTop = fitsAbove && !fitsBelow;
                $target.toggleClass('available--top', expandAtTop);
                $target.removeAttr('hidden');
            } else {
                $target.attr('hidden', '');
                $search.val('');
                $answers.removeAttr('hidden');
                $clearSearch.attr('hidden', '');
            }
        }
    };

    var updateState = function () {
        var $visible = $current.children('[data-list-item]:not([hidden])');

        $current.toggleClass('empty', $visible.length === 0);

        if (multi) {
            $visible.each(function (index) {
                $(this).toggleClass('comma-separated', index < $visible.length-1);
            });
        }

        $widget.trigger('change');
    };

    updateState();

    connect();

    $widget.on('click', onTriggerClick($widget, $trigger, $target));
    $availableItems.on('blur', function(e) {
        if (!$available.find(e.relatedTarget).length && e.relatedTarget) {
            $widget.trigger('click');
        }
    });

    $(document).on('click', function(e) {
        var clickedOutside = !this.is(e.target) && this.has(e.target).length === 0;
        var clickedInDialog = $(e.target).closest(".modal").length !== 0;
        if (clickedOutside && !clickedInDialog) {
            var isCurrentlyExpanded = $trigger.attr('aria-expanded') === 'true';
            if (isCurrentlyExpanded) {
                onTriggerClick($widget, $trigger, $target)();
            }
        }
    }.bind(this));

    $(document).keyup(function(e) {
        if (e.keyCode == 27) {
            var isCurrentlyExpanded = $trigger.attr('aria-expanded') === 'true';
            if (isCurrentlyExpanded) {
                onTriggerClick($widget, $trigger, $target)();
            }
        }
    });

    $search.on('keyup', function() {
      var searchValue = $(this).val().toLowerCase();

      // hide the answers that do not contain the searchvalue
      $.each($answers, function() {
        var labelValue = $(this).find('label')[0].innerHTML.toLowerCase();
        if (labelValue.indexOf(searchValue) === -1) {
            $(this).attr('hidden', '');
        } else {
            $(this).removeAttr('hidden', '');
        }
      });

      if (searchValue.length) {
        $clearSearch.removeAttr('hidden');
      } else {
        $clearSearch.attr('hidden', '');
      }
    });

    $clearSearch.on('click', function() {
        $search.val('');
        $answers.removeAttr('hidden');
        $clearSearch.attr('hidden', '');
    });

    $widget.addClass("hasSelectWidget");
    $widget.prop('tabIndex', -1);
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
    var type = $depends.data('column-type');

    if (type === 'enum' || type === 'curval') {
        var $visible = $depends.find('.select-widget .current [data-list-item]:not([hidden])');
        var items = [];
        $visible.each(function () { items.push($(this).text()) });
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
    var $field   = this.field;
    var $depends = this.dependsOn;
    var regexp   = this.regexp;

    var some = function (set, test) {
        for (var i = 0, j = set.length; i < j; i++) {
            if (test(set[i])) {
                return true;
            }
        }
        return false;
    };

    $depends.on('change', function (e) {
        var values = getFieldValues($depends);
        some(values, function (value) {
            return regexp.test(value)
        }) ? $field.show() : $field.hide();
    });

    // trigger a change to toggle all dependencies
    $depends.trigger('change');
};

var setupDependentFields = function (context) {
    var fields = $('[data-has-dependency]').map(function () {
        var dependence = $(this).data('has-dependency');
        var pattern    = $(this).data('dependency');
        var regexp     = (new RegExp("^" + base64.decode(pattern) + "$"))

        return {
            field     : $(this),
            dependsOn : $('[data-column-id="' + dependence + '"]'),
            regexp    : regexp
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
                    return '/tree' + new Date().getTime() + '/' + id + '?' + idsAsParams;
                },
                data : function (node) {
                    return { 'id' : node.id };
                }
            },
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

var setupDisplayConditions = function(context) {
    $('#toggle-display-regex', context).on('click', function() {
        var $displayToggleButton = $(this),
            $displayConditionField = $displayToggleButton.siblings('#display_condition').first(),
            $displayField = $('#display_field'),
            $displayRegex = $('#display_regex');

        // Open and hide expanded element
        toggleDisclosure.bind($displayToggleButton).call();

        // Toggle field values
        var currentlyExpanded = $displayToggleButton.attr('aria-expanded') === 'true';
        $displayToggleButton.text(currentlyExpanded ? 'Delete condition' : 'Configure display');
        $displayConditionField.val(currentlyExpanded);

        if (!currentlyExpanded) {
            $displayField.val('');
            $displayRegex.val('');
        }
    });
}

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

var Linkspace = {
    constants: {
        ARROW_LEFT: 37,
        ARROW_RIGHT: 39
    },

    init: function (context) {
        setupLessMoreWidgets(context);
        setupDisclosureWidgets(context);
        setupSelectWidgets(context);
        setupDisplayConditions(context);
        runPageSpecificCode(context);
        setupSubmitListener(context);
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
