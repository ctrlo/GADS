var setupDisclosureWidgets = function () {
        var positionDisclosure = function (offset) {
                var $disclosure = this;
                console.debug(offset);
        };

        var toggleDisclosure = function () {
                var $trigger = $(this);
                var $disclosure = $trigger.next('expandable');
                
                return function () {
                        var offset = $trigger.offset();
                        positionDisclosure.call($disclosure, offset);

                        var currentlyExpanded = $trigger.attr('aria-expanded') === 'true';
                        $trigger.attr('aria-expanded', !currentlyExpanded');
                };
        };

        $('.trigger[aria-expandable]').on('click', toggleDisclosure());
}

var Linkspace = {
        init: function () {
                setupDisclosureWidgets();
        }
};

$.ready(Linkspace.init);
