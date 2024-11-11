import { BaseButton } from "./base-button";

class DynamicButton extends BaseButton {
    type = "btn-js-dynamic";

    constructor(element) {
        super(element);
    }

    init() {
        console.log('DynamicButton initialized');
    }

    click(ev : JQuery.ClickEvent) {
        console.log(ev.target.id + ' clicked');
    }
}

const createDynamicButton = (element: JQuery<HTMLElement>) => {
    return new DynamicButton(element);
};

export default createDynamicButton;