'use strict';

var MultiSelectWidget = function () {
    var connect = function (update) {
        return function () {
            var $item = $(this);
            var itemId = $item.data('list-item');
            var $associated = $('#' + itemId);
            $associated.on('change', function () {
                if ($(this).prop('checked')) {
                    $item.prop('hidden', false);
                } else {
                    $item.prop('hidden', true);
                }
                update();
            });
        };
    };
 
    var onTriggerClick = function ($target) {
        return function (event) {
            var isCurrentlyExpanded = $(this).attr('aria-expanded') === 'true';
            var willExpandNext = !isCurrentlyExpanded;

            if (willExpandNext) {
                $target.prop('hidden', false);
                $(this).attr('aria-expanded', 'true');
            } else {
                $(this).attr('aria-expanded', 'false');
                $target.prop('hidden', true);
            }
        }
    };
    
    var $trigger = this.find('button');
    var $current = this.find('.current');
    var $target  = this.find('#' + $trigger.attr('aria-controls'));
    var $currentItems = $current.children();

    var updateState = function () {
        var $visible = $current.children('[data-list-item]:not([hidden])');
        $current.toggleClass('empty', $visible.length === 0);
        $visible.each(function (index) {
            $(this).toggleClass('comma-separated', index < $visible.length-1); 
        });
    };

    updateState();
    $currentItems.each(connect(updateState));
    $trigger.on('click', onTriggerClick($target));   
};

var setupMultiSelectWidgets = function () {
    var $nodes = $('.select-widget.multi');
    $nodes.each(function () {
        MultiSelectWidget.call($(this));
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
        console.clear();
        setupLessMoreWidgets();
        setupDisclosureWidgets();
        setupMultiSelectWidgets();
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

Linkspace.layout = function () {
    Linkspace.debug('Layout JS firing');

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
