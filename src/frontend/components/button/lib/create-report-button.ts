import { validateRequiredFields } from "validation";
import { BaseButton } from "./base-button";

/**
 * CreateReportButtonComponent class to create a report submission button component
 */
class CreateReportButtonComponent extends BaseButton {
    type: string = "btn-js-submit";
    private canSubmitRecordForm: boolean = false;

    /**
     * Create a new CreateReportButtonComponent
     * @param {JQuery<HTMLElement>} element button element
     */
    constructor(element: JQuery<HTMLElement>) {
        super(element);
    }

    click(ev: JQuery.ClickEvent) {
        const $button = $(ev.target).closest('button');
        const $form = $button.closest("form");

        if (!this.canSubmitRecordForm) {
            ev.preventDefault();

            const isValid = validateRequiredFields($form);

            if (isValid) {
                this.canSubmitRecordForm = true;
                this.submit($button);
            }
        }
    }

    /**
     * Submit the form
     * @param {JQuery<HTMLElement>} $button form to submit
     */
    submit($button: JQuery<HTMLElement>) {
        $button.trigger("click");
        $button.prop("disabled", true);
    }
}

export default function createCreateReportButton(element: HTMLElement | JQuery<HTMLElement>) {
    return new CreateReportButtonComponent($(element));
}