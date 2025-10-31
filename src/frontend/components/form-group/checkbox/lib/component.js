import { Component } from 'component';

/**
 * Component to handle checkbox functionality with reveal elements.
 */
class CheckboxComponent extends Component {
    /**
     * Create a new instance of the CheckboxComponent.
     * @param {HTMLElement} element The HTML element that this component is attached to.
     */
    constructor(element) {
        super(element);
        this.el = $(this.element);

        this.initCheckbox();
    }

    /**
     * Intializes the checkbox
     */
    initCheckbox() {
        const inputEl = $(this.el).find('input');
        const id = $(inputEl).attr('id');
        const $revealEl = $(`#${id}-reveal`);

        if ($(inputEl).is(':checked')) {
            this.showRevealElement($revealEl, true);
        }

        $(inputEl).on('change', () => {
            if ($(inputEl).is(':checked')) {
                this.showRevealElement($revealEl, true);
            } else {
                this.showRevealElement($revealEl, false);
            }
        });
    }

    /**
     * Show or hide the reveal element based on the checkbox state.
     * @param {JQuery<HTMLElement>} $revealEl The reveal element to show or hide
     * @param {boolean} bShow True to show the reveal element, false to hide it
     */
    showRevealElement($revealEl, bShow) {
        const strCheckboxRevealShowClassName = 'checkbox-reveal--show';

        if (bShow) {
            $revealEl.addClass(strCheckboxRevealShowClassName);
        } else {
            $revealEl.removeClass(strCheckboxRevealShowClassName);
        }
    }
}

export default CheckboxComponent;
