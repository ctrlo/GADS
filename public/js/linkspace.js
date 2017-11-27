var MultiSelectWidget = function () {
    var addComma = function () {
        var $visible = $currentItems.filter(function () {
            return $(this).attr('hidden') !== undefined;
        });

        $visible.each(function (index) {
            $(this).toggleClass('comma-separated', index < $visible.length-1); 
        });
    };

    var connect = function () {
        var $item = $(this);
        var itemId = $item.data('list-item');
        var $associated = $('#' + itemId);
        $associated.on('change', function () {
            if ($(this).prop('checked')) {
                $item.prop('hidden', false);
            } else {
                $item.prop('hidden', true);
            }
            addComma();
        });
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
    var $currentItems = this.find('.current li');
    var $target = this.find('#' + $trigger.attr('aria-controls'));

    addComma();
    $currentItems.each(connect);
    $trigger.on('click', onTriggerClick($target));   
};

var setupMultiSelectWidgets = function () {
    var $nodes = $('.select-widget.multi');
    $nodes.each(function () {
        MultiSelectWidget.call($(this));
    });
};

$(setupMultiSelectWidgets);

