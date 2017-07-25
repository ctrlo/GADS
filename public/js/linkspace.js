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
        var $disclosure = $trigger.next('.expandable');

        var offset = $trigger.position();
        positionDisclosure.call(
            $disclosure, offset.top, offset.left, $trigger.height()
        );

        var currentlyExpanded = $trigger.attr('aria-expanded') === 'true';
        $trigger.attr('aria-expanded', !currentlyExpanded);
    };

    $('.trigger[aria-expanded]').on('click', toggleDisclosure);
}

var Linkspace = {
    init: function () {
        setupDisclosureWidgets();
    }
};

$(Linkspace.init);
