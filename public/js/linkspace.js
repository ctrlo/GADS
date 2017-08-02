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
            'class' : 'expandable column-content',
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
            if (state === 'expanded') {
                $expandable.css('width', $ml.width() + 'px');
            }
        });

        $ml.empty()
           .append($expandToggle)
           .append($expandable);
    };

    var $widgets = $('.more-less');
    $widgets.each(convert);
};

var setupDisclosureWidgets = function () {
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
        positionDisclosure.call(
            $disclosure, offset.top, offset.left, $trigger.height()
        );

        var currentlyExpanded = $trigger.attr('aria-expanded') === 'true';
        $trigger.attr('aria-expanded', !currentlyExpanded);

        var expandedLabel = $trigger.data('label-expanded');
        var collapsedLabel = $trigger.data('label-collapsed');

        if (collapsedLabel.length && expandedLabel.length) {
            $trigger.html(currentlyExpanded ? collapsedLabel : expandedLabel);
        }

        $trigger.trigger('toggle', currentlyExpanded ? 'collapsed' : 'expanded');
    };

    $('.trigger[aria-expanded]').on('click', toggleDisclosure);
}

var Linkspace = {
    init: function () {
        setupLessMoreWidgets();
        setupDisclosureWidgets();
    }
};

$(Linkspace.init);
