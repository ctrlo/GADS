import { Component } from 'component';

export default class FieldLengthComponent extends Component {
    constructor(element: HTMLElement) {
        super(element);
        if (!(element instanceof HTMLTextAreaElement) && !(element instanceof HTMLInputElement)) {
            throw new Error('Element must be a textarea or input');
        }
        this.init();
    }

    private init() {
        const input = this.element as HTMLTextAreaElement | HTMLInputElement;
        if (!input) return;
        if(!input.dataset.max) return;
        this.createCounter(input);
        input.addEventListener('keyup', () => this.updateCounter(input));
    }

    private createCounter(input: HTMLTextAreaElement | HTMLInputElement) {
        const max = parseInt(input.dataset.max || '0', 10);
        const counter = document.createElement('div');
        counter.classList.add('counter');
        counter.textContent = `${input.value.length}/${max}`;
        input.insertAdjacentElement('afterend', counter);
    }

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