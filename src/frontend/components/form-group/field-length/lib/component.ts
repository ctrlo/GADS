import { Component } from 'component';

/**
 * A component that displays the length of a field and the maximum length allowed.
 */
export default class FieldLengthComponent extends Component {
    /**
     * Create a new FieldLengthComponent instance.
     */
    constructor(element: HTMLElement) {
        super(element);
        if (!(element instanceof HTMLTextAreaElement) && !(element instanceof HTMLInputElement)) {
            throw new Error('Element must be a textarea or input');
        }
        this.init();
    }

    /**
     * Initialize the component by creating a counter and adding an event listener to update it on keyup.
     */
    private init() {
        const input = this.element as HTMLTextAreaElement | HTMLInputElement;
        if (!input) return;
        if(!input.dataset.max) return;
        this.createCounter(input);
        input.addEventListener('keyup', () => this.updateCounter(input));
    }

    /**
     * Create a counter element that displays the current length of the input value and the maximum length allowed.
     */
    private createCounter(input: HTMLTextAreaElement | HTMLInputElement) {
        const max = parseInt(input.dataset.max || '0', 10);
        const counter = document.createElement('div');
        counter.classList.add('counter');
        counter.textContent = `${input.value.length}/${max}`;
        input.insertAdjacentElement('afterend', counter);
    }

    /**
     * Update the counter element with the current length of the input value and the maximum length allowed. If the current length exceeds the maximum length, add an 'invalid' class to the counter element.
     */
    private updateCounter(input: HTMLTextAreaElement | HTMLInputElement) {
        const max = parseInt(input.dataset.max || '0', 10);
        const counter = input.nextElementSibling as HTMLElement;
        const length = input.value.length;
        counter.textContent = `${length}/${max}`;
        if(length>max) {
            if(!counter.classList.contains('invalid')) {
                counter.classList.add('invalid');
            }
        } else if(counter.classList.contains('invalid')) {
            counter.classList.remove('invalid');
        }
    }
}
