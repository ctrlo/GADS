class PasswordComponent {
    // For testing purposes
    protected readonly type = 'password';

    el: JQuery<HTMLElement>;
    btnReveal: JQuery<HTMLElement>;
    input: JQuery<HTMLInputElement>;

    constructor(el: JQuery<HTMLElement> | HTMLElement) {
        this.el = $(el);
        this.btnReveal = this.el.find('.input__reveal-password');
        this.input = this.el.find('.form-control') as JQuery<HTMLInputElement>;
    }

    init() {
        if (this.btnReveal.length === 0) return;

        this.btnReveal.removeClass('show').on('click', this.handleClickReveal);
    }

    private handleClickReveal = () => {
        const inputType = this.input.attr('type');
        this.input.attr('type', inputType === 'password' ? 'text' : 'password');
        this.btnReveal.toggleClass('show');
    };
}

export default function passwordComponent(el: JQuery<HTMLElement> | HTMLElement) {
    new PasswordComponent(el).init();
}
