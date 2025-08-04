import initDateField from '../../../datepicker/lib/helper';

class DateComponent {
    readonly type = 'date';
    el: JQuery<HTMLElement>;
    input: JQuery<HTMLInputElement>;

    constructor(el: JQuery<HTMLElement> | HTMLElement) {
        this.el = el instanceof HTMLElement ? $(el) : el;
        this.input = this.el.find<HTMLInputElement>('.form-control');
    }

    init() {
        initDateField(this.input);
    }
}

export default function dateComponent(el: JQuery<HTMLElement> | HTMLElement) {
    (new DateComponent(el)).init();
}
