import {validateRequiredFields} from 'validation';

/**
 * CreateReportButtonComponent class to create a report submission button component
 */
export default class CreateReportButtonComponent {
    private canSubmitRecordForm: boolean = false;

    /**
     * Create a new CreateReportButtonComponent
     * @param {JQuery<HTMLElement>} element button element
     */
    constructor(element:JQuery<HTMLElement>) {
        element.on('click', (ev) => {
            const $button = $(ev.target).closest('button');
            const $form = $button.closest('form');

            if (!this.canSubmitRecordForm) {
                ev.preventDefault();

                const isValid = validateRequiredFields($form);

                if (isValid) {
                    this.canSubmitRecordForm = true;
                    this.submit($button);
                }
            }
        });
    }

    /**
     * Submit the form
     * @param {JQuery<HTMLElement>} $button form to submit
     */
    submit($button:JQuery<HTMLElement>) {
        $button.trigger('click');
        $button.prop('disabled', true);
    }
}
