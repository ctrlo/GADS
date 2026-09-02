import { Component } from "component";

/**
 * Component to display the character count on a text or input field with a max length.
 * It will display the current character count and the max length, and will add an "invalid"
 * class to the counter if the current length exceeds the max length.
 */
export default class FieldLengthComponent extends Component {
    /**
     * Creates a new FieldLengthComponent instance.
     * @param element The element to attach the counter to
     */
    constructor(element: HTMLElement) {
        super(element);
        if (!(element instanceof HTMLTextAreaElement) && !(element instanceof HTMLInputElement)) {
            throw new Error("Element must be a textarea or input");
        }
        this.init();
    }

    /**
     * Initializes the component by creating the counter and adding the event listener for keyup events.
     */
    private init() {
        const input = this.element as HTMLTextAreaElement | HTMLInputElement;
        if (!input) return;
        if(!input.dataset.max) return;
        this.createCounter(input);
        input.addEventListener("keyup", () => this.updateCounter(input));
    }

    /**
     * Create the counter element and insert it after the input field.
     * @param input The input field to assign the counter to
     */
    private createCounter(input: HTMLTextAreaElement | HTMLInputElement) {
        const max = parseInt(input.dataset.max || "0", 10);
        const counter = document.createElement("div");
        counter.classList.add("counter");
        counter.textContent = `${input.value.length}/${max}`;
        input.insertAdjacentElement("afterend", counter);
    }

    /**
     * Update a counter when the data needs to be updated.
     * @param input The input field to update the counter for
     */
    private updateCounter(input: HTMLTextAreaElement | HTMLInputElement) {
        const max = parseInt(input.dataset.max || "0", 10);
        const counter = input.nextElementSibling as HTMLElement;
        const length = input.value.length;
        counter.textContent = `${length}/${max}`;
        if(length>max) {
            if(!counter.classList.contains("invalid")) {
                counter.classList.add("invalid");
            }
        } else if(counter.classList.contains("invalid")) {
            counter.classList.remove("invalid");
        }
    }
}
