import { Component } from 'component';

/**
 * SelectAllComponent class to manage the behavior of a "select all" checkbox.
 */
export default class SelectAllComponent extends Component {
    el: JQuery<HTMLInputElement>;

    /**
     * Creates an instance of SelectAllComponent.
     * @param {HTMLElement} element The HTML element representing the "select all" checkbox.
     */
    constructor(element: HTMLElement) {
        super(element);
        this.el = $<HTMLInputElement>(element as HTMLInputElement);
        this.element.addEventListener('change', () => this.onChange());
    }

    /**
     * Handles the change event of the "select all" checkbox.
     */
    onChange() {
        const parent = this.el.closest('fieldset');
        const boxes = parent.find('input[type=checkbox]');
        boxes.toArray().forEach(item => {
            if (item === this.el[0]) return;
            console.log('item', item);
            const i = <HTMLInputElement>item;
            i.checked = (<HTMLInputElement>this.el[0]).checked;
        });
    }
}
