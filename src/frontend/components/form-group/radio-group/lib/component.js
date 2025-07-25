import { Component } from 'component';
import { initValidationOnField } from 'validation';

/**
 * Component for radio group form elements.
 */
class RadioGroupComponent extends Component {
    /**
     * Create a new RadioGroupComponent.
     * @param {HTMLElement} element The HTML element for the radio group.
     */
    constructor(element) {
        super(element);
        this.el = $(this.element);

        if (this.el.hasClass('radio-group--required')) {
            initValidationOnField(this.el);
        }
    }
}

export default RadioGroupComponent;
