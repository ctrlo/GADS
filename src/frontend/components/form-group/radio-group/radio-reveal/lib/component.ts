import { Component } from "component";
import { hideElement, showElement } from "util/common";

export default class RadioRevealComponent extends Component {
    private el: JQuery<HTMLElement>;

    constructor(element: HTMLElement) {
        super(element);
        this.el = $(this.element);
        this.init();
    }

    private init() {
        const target = this.el.data("radio-target");
        const value = this.el.data("radio-value");

        if (!target || !value) {
            console.error("RadioRevealComponent: Missing data-radio-target or data-radio-value attribute.");
            return;
        }

        const radioButtons = $(`input[name="${target}"]`);

        radioButtons.on("change", () => {
            this.toggleVisibility(radioButtons, value);
        });

        // Initial check
        this.toggleVisibility(radioButtons, value);
    }

    toggleVisibility(radioButtons: JQuery<HTMLElement>, value: string) {
        if (radioButtons.filter(":checked").val() == value) {
                showElement(this.el);
            } else {
                hideElement(this.el);
            }
    }
}
