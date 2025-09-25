/**
 * Control to handle and display errors within the UI
 */
export class ErrorHandler {
    private el: JQuery<HTMLElement>;
    private errors: string[] = [];
    errorContainer: JQuery<HTMLElement>;

    /**
     * Create a new ErrorHandler instance
     * @param element The element to attach the control to
     */
    constructor(private element: HTMLElement) {
        this.el = $(element);
        this.el.data['errorHandler'] = this;
        this.initErrorDisplay();
    }

    /**
     * Initialise the display for the errors
     */
    private initErrorDisplay() {
        this.errorContainer = $('<div class="error-container p-3 alert alert-danger font-weight-bold my-3 flex-column align-items-start"></div>');
        this.el.prepend(this.errorContainer);
        this.renderErrors();
    }

    /**
     * Add error(s) to the display
     * @param errors The error(s) to add to the display
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
     * Clear the errors from the display
     */
    clearErrors() {
        this.errors = [];
        this.renderErrors();
    }

    /**
     * Render any errors present in the control
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
            this.errorContainer.hide();
        }
    }
}
