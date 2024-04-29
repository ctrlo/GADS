import {validateRequiredFields} from "validation";
import {stopPropagation} from "util/common";

/**
 * CreateReportButtonComponent class to create a report submission button component
 */
export default class CreateReportButtonComponent {
    /**
     * Create a new CreateReportButtonComponent
     * @param {JQuery<HTMLButtonElement>} element button element
     */
    constructor(element) {
        this.canSubmitRecordForm = false;

        element.on('click', (ev) => {
            const $button = $(ev.target).closest('button');
            const $form = $button.closest("form");

            if (!this.canSubmitRecordForm) {
                stopPropagation(ev);

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
     * @param {jQuery<HTMLButtonElement>} $button form to submit
     */
    submit($button) {
        $button.trigger("click");
        $button.prop("disabled", true);
    }
}
