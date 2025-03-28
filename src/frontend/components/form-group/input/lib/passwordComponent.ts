/**
 * Password Component
 */
class PasswordComponent {
    protected readonly type = 'password';

    el: JQuery<HTMLElement>;
    btnReveal: JQuery<HTMLElement>;
    input: JQuery<HTMLInputElement>;

    /**
     * Create a new Password component
     * @param el The element to attach the password component to
     */
    constructor(el: JQuery<HTMLElement> | HTMLElement) {
        this.el = $(el);
        this.btnReveal = this.el.find('.input__reveal-password');
        this.input = this.el.find('.form-control') as JQuery<HTMLInputElement>;
    }

    /**
     * Initialize the password component
     */
    init() {
        if (this.btnReveal.length === 0) return;

        this.btnReveal.removeClass('show').on('click', this.handleClickReveal);
    }

    /**
     * Handle a click on the reveal password button
     */
    private handleClickReveal = () => {
        const inputType = this.input.attr('type');
        this.input.attr('type', inputType === 'password' ? 'text' : 'password');
        this.btnReveal.toggleClass('show');
    };
}

/**
 * Create a new password component
 * @param el The element to attach the password component to
 */
export default function passwordComponent(el: JQuery<HTMLElement> | HTMLElement) {
    (new PasswordComponent(el)).init();
}
