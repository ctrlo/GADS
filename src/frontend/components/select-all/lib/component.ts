import { Component } from "component";

/**
 * Select all component for checkboxes
 */
export default class SelectAllComponent extends Component {
    private el: JQuery<HTMLInputElement>;

    /**
     * Create a new SelectAllComponent
     * @param element The element to attach the select all functionality to
     */
    constructor(element: HTMLElement) {
        super(element);
        this.el = $<HTMLInputElement>(element as HTMLInputElement);
        this.element.addEventListener("change", () => this.onChange());
    }

    /**
     * Trigged when the select all checkbox is changed
     */
    onChange() {
        const parent = this.el.closest('fieldset');
        const boxes = parent.find("input[type=checkbox]");
        boxes.toArray().forEach(item => {
            if (item === this.el[0]) return;
            console.log("item", item);
            const i = <HTMLInputElement>item;
            i.checked = (<HTMLInputElement>this.el[0]).checked;
        });
    }
}