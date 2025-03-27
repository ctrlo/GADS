import initDateField from "../../../datepicker/lib/helper";

/**
 * Date component
 */
class DateComponent {
    readonly type = 'date';
    el: JQuery<HTMLElement>;
    input: JQuery<HTMLInputElement>;

    /**
     * Create a new date component
     * @param el The element to attach the date component to
     */
    constructor(el: JQuery<HTMLElement> | HTMLElement) {
        this.el = el instanceof HTMLElement ? $(el) : el;
        this.input = this.el.find<HTMLInputElement>('.form-control');
    }

    /**
     * Initialize the date component
     */
    init() {
        initDateField(this.input);
    }
}

/**
 * Create a new date component
 * @param el The element to attach the date component to
 */
export default function dateComponent(el: JQuery<HTMLElement> | HTMLElement) {
    (new DateComponent(el)).init();
}
