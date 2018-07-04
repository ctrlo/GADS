'use strict';

/* 
 * A SelectWidget is a custom disclosure widget
 * with multi or single options selectable.
 * SelectWidgets can depend on each other;
 * for instance if Value "1" is selected in Widget "A",
 * Widget "B" might not be displayed.
 */
var SelectWidget = function (multi) {

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

    var connectSingle = function (update) {
        return function () {
            var $item = $(this);
            var itemId = $item.data('list-item');
            var $associated = $('#' + itemId);
            $associated.on('change', function (e) {
                e.stopPropagation();
                update($item);
            });
        };
    };
 
    var onTriggerClick = function ($widget, $trigger, $target) {
        return function (event) {
            var isCurrentlyExpanded = $trigger.attr('aria-expanded') === 'true';
            var willExpandNext = !isCurrentlyExpanded;

            $trigger.attr('aria-expanded', willExpandNext);

            if (willExpandNext) {
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

    var isSingle = this.hasClass('single');

    var $container = $('main');
    var $widget = this.find('.form-control');
    var $trigger = $widget.find('[aria-expanded]');
    var $current = this.find('.current');
    var $availableItems = this.find('.available .answer input');
    var $target  = this.find('#' + $trigger.attr('aria-controls'));
    var $currentItems = $current.children();
    var $answers = this.find('.answer');
    var $search = this.find('.form-control-search');
    var $clearSearch = this.find('.form-control-search__clear');

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

    if (multi) {
        $currentItems.each(connectMulti(updateState));
    } else {
        $currentItems.each(connectSingle(function ($connected) {
            $currentItems.each(function () {
                $(this).attr('hidden', '');
            });

            $current.toggleClass('empty', false);
            $connected.removeAttr('hidden');

            $widget.trigger('change');
        }));
    }

    $availableItems.on('click', function () {
        if (!isSingle) return;
        onTriggerClick($widget, $trigger, $target)();
    });

    $widget.on('click', onTriggerClick($widget, $trigger, $target));

    $(document).on('click', function(e) {
        var clickedOutside = !this.is(e.target) && this.has(e.target).length === 0;
        if (clickedOutside) {
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
};

var setupSelectWidgets = function () {
    var $nodes = $('.select-widget');
    $nodes.each(function () {
        var multi = $(this).hasClass('multi');
        SelectWidget.call($(this), multi);
    });
};

var setupLessMoreWidgets = function () {
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

    var $widgets = $('.more-less');
    $widgets.each(convert);
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

    // get the value from a field, depending on its type
    var getFieldValues = function ($depends, $target) {
        var type = $depends.data('column-type');

        if (type === 'enum' || type === 'curval') {
            var $visible = $depends.find('.select-widget .current [data-list-item]:not([hidden])');
            var items = [];
            $visible.each(function () { items.push($(this).text()) });
            return items;
        } else if (type === 'person') {
            return [$target.find('option:selected').text()];
        } else if (type === 'tree') {
            // get the hidden children of $target, their value attr is the selected values
            var items = [];
            $target.find('.selected-tree-value').each(function() { items.push($(this).val()) });
            return items;
        } else {
            return [$target.val()];
        }
    };

    var some = function (set, test) {
        for (var i = 0, j = set.length; i < j; i++) {
            if (test(set[i])) {
                return true;
            }
        }
        return false;
    };

    $depends.on('change', function (e, params) {
        var $target = $(e.target);
        var values = params ? params.values : getFieldValues($depends, $target);
        some(values, function (value) {
            return regexp.test(value)
        }) ? $field.show() : $field.hide();
    });

    // trigger a change to toggle all dependencies
    $depends.trigger('change');
};

var setupDependentFields = function () {
    var fields = $('[data-has-dependency]').map(function () {
        var dependence = $(this).data('has-dependency');
        var pattern    = $(this).data('dependency');
        var regexp     = (new RegExp("^" + base64.decode(pattern) + "$"))

        return {
            field     : $(this).parent(),
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
        $treeContainer.find('.selected-tree-value').remove();
        var selectedElms = $treeContainer.jstree("get_selected", true);

        var values = [];

        $.each(selectedElms, function () {
            // store the selected values in hidden fields as children of the element
            $treeContainer.append(
                '<input type="hidden" class="selected-tree-value" name="' + field + '" value="' + this.id + '" />'
            );
            values.push(data.instance.get_path(this, '#'));
        });

        $treeContainer.trigger('change', { values: values });
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

var setupTreeFields = function () {
    var $fields = $('[data-column-type="tree"]');
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

var setupDisclosureWidgets = function () {
    $('.trigger[aria-expanded]').on('click', toggleDisclosure);
}

var runPageSpecificCode = function () {
    var page = $('body').data('page').match(/^(.*?)(:?\/\d+)?$/);
    if (page === null) { return; }

    var handler = Linkspace[page[1]];
    if (handler !== undefined) {
        handler();
    }
};

var Linkspace = {
    constants: {
        ARROW_LEFT: 37,
        ARROW_RIGHT: 39
    },

    init: function () {
        setupLessMoreWidgets();
        setupDisclosureWidgets();
        setupSelectWidgets();
        runPageSpecificCode();
    },

    debug: function (msg) {
        console.debug('[LINKSPACE]', msg);
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

Linkspace.edit = function () {
    Linkspace.debug('Record edit JS firing');
    setupTreeFields();
    setupDependentFields();
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

$(Linkspace.init);
