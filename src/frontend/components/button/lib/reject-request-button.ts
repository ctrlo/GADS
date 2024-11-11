import { BaseButton } from "./base-button";

declare global {
    interface JQuery<TElement = HTMLElement> {
        rejectRequestButton(): JQuery<TElement>;
    }
}

class RejectRequestButton extends BaseButton {
    type = "btn-js-reject-request";

    constructor(element) {
        super(element);
    }

    init() {
        console.log('RejectRequestButton initialized');
    }

    click(ev : JQuery.ClickEvent) {
        console.log(ev.target.id + ' clicked');
    }
}

const createRejectRequestButton = (element: JQuery<HTMLElement>) => {
    return new RejectRequestButton(element);
};

export default createRejectRequestButton;

// Better global method for adding button functionality via jQuery
(function ($) {
    $.fn.rejectRequestButton = function () {
        return this.each(function () {
            createRejectRequestButton($(this));
        });
    };
})(jQuery);