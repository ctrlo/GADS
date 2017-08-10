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
        
        $disclosure.toggleClass('expanded', !currentlyExpanded);

        $trigger.trigger((currentlyExpanded ? 'collapse' : 'expand'), $disclosure);
    };

    $('.trigger[aria-expanded]').on('click', toggleDisclosure);
}

var runPageSpecificCode = function () {
    var page = $('body').data('page');
    var handler = Linkspace[page];
    if (handler !== undefined) {
        handler();
    }
};

var Linkspace = {
    init: function () {
        console.clear();
        setupDisclosureWidgets();
        runPageSpecificCode();
    },
    debug: function (msg) {
        console.debug('[LINKSPACE]', msg);
    }
};

Linkspace.layout = function () {
    Linkspace.debug('Layout JS firing');
    $('#show-advanced-field-settings').on('expand', function (event, target) {
        $(target).find('h3').focus();
        $(this).remove();
    });
};

$(Linkspace.init);
