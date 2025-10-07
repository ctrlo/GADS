import initDateField from '../../../datepicker/lib/helper';

/**
 * DateComponent class to handle date input fields.
 */
class DateComponent {
    readonly type = 'date';
    el: JQuery<HTMLElement>;
    input: JQuery<HTMLInputElement>;

    /**
     * Creates an instance of DateComponent.
     * @param {JQuery<HTMLElement> | HTMLElement} el The element to initialize the date component on, can be a jQuery object or a native HTMLElement.
     */
    constructor(el: JQuery<HTMLElement> | HTMLElement) {
        this.el = el instanceof HTMLElement ? $(el) : el;
        this.input = this.el.find<HTMLInputElement>('.form-control');
    }

    /**
     * Initializes the date input field. This is really just a wrapper around the datepicker initialization.
     */
    init() {
        initDateField(this.input);
    }
}

/**
 * Create and initialize a date component.
 * @param {JQuery<HTMLElement> | HTMLElement} el The element to initialize the date component on, can be a jQuery object or a native HTMLElement.
 */
export default function dateComponent(el: JQuery<HTMLElement> | HTMLElement) {
    (new DateComponent(el)).init();
}
