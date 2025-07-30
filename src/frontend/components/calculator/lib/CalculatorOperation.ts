/**
 * CalculatorOperation class to represent a calculator operation.
 */
export class CalculatorOperation {
    /**
     * Creates an instance of CalculatorOperation.
     * @param {string} action Action name for the operation (e.g., 'add', 'subtract').
     * @param {string} label Label for the operation button (e.g., '+', '-').
     * @param {string[]} keypress Keypresses that trigger the operation (e.g., ['+', '-']).
     * @param {(a:number, b:number)=>number} operation
     */
    constructor(private action: string, private label: string, private keypress: string[], private operation: (a:number, b:number) => number) {
    }

    /**
     * Renders the HTML structure for the operation button.
     * @returns {JQuery<HTMLElement>} A jQuery object representing the HTML structure of the operation button.
     */
    render(): JQuery<HTMLElement> {
        return $(
            `<div class="radio-group__option">
                <input type="radio" name="op" id="op_${this.action}" class="radio-group__input btn_label_${this.action}">
                <label class="radio-group__label" for="op_${this.action}">${this.label}</label>
            </div>`
        );
    }
}
