/**
 * PasswordComponent class for handling password input fields with reveal functionality.
 */
class PasswordComponent {
    // For testing purposes
    protected readonly type = 'password';

    el: JQuery<HTMLElement>;
    btnReveal: JQuery<HTMLElement>;
    input: JQuery<HTMLInputElement>;

    /**
     * Create a new PasswordComponent.
     * @param {JQuery<HTMLElement|HTMLElement>} el The HTML element for the password component, can be a jQuery object or a plain HTMLElement.
     */
    constructor(el: JQuery<HTMLElement> | HTMLElement) {
        this.el = $(el);
        this.btnReveal = this.el.find('.input__reveal-password');
        this.input = this.el.find('.form-control') as JQuery<HTMLInputElement>;
    }

    /**
     * Initialize the PasswordComponent.
     */
    init() {
        if (this.btnReveal.length === 0) return;

        this.btnReveal.removeClass('show').on('click', this.handleClickReveal);
    }

    /**
     * Handle the click event to toggle password visibility.
     */
    private handleClickReveal = () => {
        const inputType = this.input.attr('type');
        this.input.attr('type', inputType === 'password' ? 'text' : 'password');
        this.btnReveal.toggleClass('show');
    };
}

/**
 * Create a new PasswordComponent.
 * @param {HTMLElement | JQuery<HTMLElement>} el The HTML element for the password component.
 */
export default function passwordComponent(el: JQuery<HTMLElement> | HTMLElement) {
    new PasswordComponent(el).init();
}
