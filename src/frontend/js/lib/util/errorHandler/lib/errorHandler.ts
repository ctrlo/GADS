export class ErrorHandler {
    private el: JQuery<HTMLElement>;
    private errors: string[] = [];
    errorContainer: JQuery<HTMLElement>;

    constructor(private element: HTMLElement) {
        this.el = $(element);
        this.el.data['errorHandler'] = this;
        this.initErrorDisplay();
    }

    private initErrorDisplay() {
        this.errorContainer = $('<div class="error-container p-3 alert alert-danger font-weight-bold my-3 flex-column align-items-start"></div>')
        this.el.prepend(this.errorContainer);
        this.renderErrors();
    }

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

    clearErrors() {
        this.errors = [];
        this.renderErrors();
    }

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