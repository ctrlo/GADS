import { Renderable } from "../../common/Renderable";

/**
 * A class to handle progress rendering in a parent HTML element.
 */
export class Progress implements Renderable {
    private _value = 0;
    /**
     * Flag to indicate if the progress value has changed since the last render.
     * This is used to avoid unnecessary re-rendering.
     * @type {boolean}
     * @private
     * @default false
     */
    private changed = false;

    /**
     * Gets the current value of the progress.
     * @returns {number} The current value of the progress.
     */
    get value(): number {
        return this._value;
    }

    /**
     * Sets the value of the progress. If the value is out of bounds (less than 0 or greater than total),
     * it will be clamped to the nearest valid value.
     * @param {number} newValue - The new value to set for the progress.
     */
    set value(newValue: number) {
        if (newValue < 0 || newValue > this.total) {
            newValue = Math.max(0, Math.min(newValue, this.total));
        }
        this._value = newValue;
        this.changed = true;
    }

    /**
     * Create a new Progress instance.
     * @param {HTMLElement} parent The parent HTML element where the progress bar will be rendered.
     * @param {string} identifier The identifier for the progress bar, used for accessibility and querying.
     * @param {number} total The total value that the progress bar represents.
     */
    constructor(private readonly parent: HTMLElement, private readonly identifier: string, private readonly total: number) { }

    /** @inheritdoc */
    render() {
        if (!this.changed) return;
        this.changed = false;
        const value = Math.round((this.value / this.total) * 100);
        const progressbar = $(`[data-identifier="${this.identifier}"]`);
        if (progressbar.length === 0) {
            this.parent.insertAdjacentHTML('beforeend',
                `<div class="progress" data-identifier="${this.identifier}" role="progressbar" aria-label="${this.identifier}" aria-valuenow="${this.value}" aria-valuemin="0" aria-valuemax="${this.total}">
                <div class="progress-bar" style="width: ${value}%;"></div>
            </div>`);
        } else {
            progressbar.attr('aria-valuenow', this.value.toString());
            progressbar.find('.progress-bar').css('width', `${value}%`);
            progressbar.find('.progress-bar').text(`${value}%`);
        }
    }
}
