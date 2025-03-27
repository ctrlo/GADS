import { Component } from "component";

/**
 * Select all component
 */
export default class SelectAllComponent extends Component {
    el: JQuery<HTMLInputElement>;

    /**
     * Create a Select All component
     * @param element The element to bind the component to
     */
    constructor(element: HTMLElement) {
        super(element);
        this.el = $<HTMLInputElement>(element as HTMLInputElement);
        this.element.addEventListener("change", () => this.onChange());
    }

    /**
     * Handle the change event
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