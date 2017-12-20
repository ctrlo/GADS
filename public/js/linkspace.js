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

$(setupMultiSelectWidgets);

