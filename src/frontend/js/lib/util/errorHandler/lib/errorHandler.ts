/**
 * ErrorHandler class to manage and display errors in a user-friendly way.
 */
export class ErrorHandler {
    private el: JQuery<HTMLElement>;
    private errors: string[] = [];
    errorContainer: JQuery<HTMLElement>;

    /**
     * Create a new ErrorHandler instance.
     * @param element The element to attach the error handler to.
     */
    constructor(private element: HTMLElement) {
        this.el = $(element);
        this.el.data['errorHandler'] = this;
        this.initErrorDisplay();
    }

    /**
     * Initialize the error display container.
     * This creates a container for displaying errors and prepends it to the element.
     */
    private initErrorDisplay() {
        this.errorContainer = $('<div class="error-container p-3 alert alert-danger font-weight-bold my-3 flex-column align-items-start"></div>')
        this.el.prepend(this.errorContainer);
        this.renderErrors();
    }

    /**
     * Add errors to the error handler.
     * This can accept either strings or Error objects.
     * It will convert Error objects to their message strings.
     * @param errors An array of error messages or Error objects to add to the error handler.
     */
    addError(...errors: (string | Error)[]) {
        errors.forEach(error => {
            if (typeof error === 'string') {
                this.errors.push(error);
            } else if (error instanceof Error) {
                this.errors.push(error.message);
            } else {
                console.warn('Unsupported error type:', error);
                this.errors.push('An unknown error occurred');
            }
        });
        this.renderErrors();
    }

    /**
     * Clear all errors from the error handler.
     */
    clearErrors() {
        this.errors = [];
        this.renderErrors();
    }

    /**
     * Render the errors in the error container.
     */
    private renderErrors() {
        this.errorContainer.empty();
        if (this.errors.length > 0) {
            this.errorContainer.show();
            this.errors.forEach(error => {
                const errorElement = $('<p class="error-message mx-1 my-2"></p>').text(error);
                this.errorContainer.append(errorElement);
            });
        } else {
            console.log('No errors to display');
            this.errorContainer.hide();
        }
    }
}
