/**
 * ErrorHandler class for managing and displaying errors in a user interface.
 */
export class ErrorHandler {
    private el: JQuery<HTMLElement>;
    private errors: string[] = [];
    errorContainer: JQuery<HTMLElement>;

    /**
     * Creates an instance of ErrorHandler.
     * @param { HTMLElement } element The HTML element to attach the error handler to.
     */
    constructor(private element: HTMLElement) {
        this.el = $(element);
        this.el.data['errorHandler'] = this;
        this.initErrorDisplay();
    }

    /**
     * Initializes the error display container.
     */
    private initErrorDisplay() {
        this.errorContainer = $('<div class="error-container p-3 alert alert-danger font-weight-bold my-3 flex-column align-items-start"></div>');
        this.el.prepend(this.errorContainer);
        this.renderErrors();
    }

    /**
     * Adds an error message or Error object to the error handler.
     * @param errors An array of error messages or Error objects to be added to the error handler.
     */
    addError(...errors: (string | Error)[]) {
        errors.forEach(error => {
            if (typeof error === 'string') {
                this.errors.push(error);
            } else if (error instanceof Error) {
                this.errors.push(error.message);
            } else if (typeof error === 'object' && error !== null && 'message' in error) {
                this.errors.push((<any>error).message);
            } else {
                console.warn('Unsupported error type:', error);
                this.errors.push('An unknown error occurred');
            }
        });
        this.renderErrors();
    }

    /**
     * Clears all errors from the error handler and updates the display.
     */
    clearErrors() {
        this.errors = [];
        this.renderErrors();
    }

    /**
     * Renders the error messages in the error container.
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
