import { BaseButton } from "./base-button";
import 'bootstrap';

declare global {
    interface JQuery<TElement = HTMLElement> {
        rejectRequestButton(): JQuery<TElement>;
    }
}

class RejectRequestButton extends BaseButton {
    type = "btn-js-reject-request";

    constructor(element: JQuery<HTMLElement>) {
        super(element);
    }

    init() {
        console.log('RejectRequestButton initialized');
    }

    click(ev? : JQuery.ClickEvent) {
        const currentWizard = ev.target.closest('.modal');
        const reason = $('#rejectReason');
        console.log('#rejectReason', reason);
        $(currentWizard).modal('toggle');
        reason.modal('toggle');
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