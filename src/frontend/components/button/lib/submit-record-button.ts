import { validateRequiredFields } from "validation";
import { BaseButton } from "./base-button";

/**
 * Button to submit records
 */
class SubmitRecordButton extends BaseButton {
    type = 'btn-js-submit-record';
    private requiredHiddenRecordDependentFieldsCleared: boolean = false;
    private canSubmitRecordForm: boolean = false;
    private disableButton: boolean = false;

    click(ev: JQuery.ClickEvent) {
        const $button = $(ev.target).closest('button');
        const $form = $button.closest("form");
        const $requiredHiddenRecordDependentFields = $form.find(".form-group[data-has-dependency='1'][style*='display: none'] *[aria-required]");
        const $parent = $button.closest('.modal-body');

        if (!this.requiredHiddenRecordDependentFieldsCleared) {
            ev.preventDefault();

            // Remove the required attribute from hidden required dependent fields
            $requiredHiddenRecordDependentFields.removeAttr('required');
            this.requiredHiddenRecordDependentFieldsCleared = true;
        }

        if (!this.canSubmitRecordForm) {
            ev.preventDefault();

            const isValid = validateRequiredFields($form);

            if (isValid) {
                this.canSubmitRecordForm = true;
                this.disableButton = false;
                if ($parent.hasClass('modal-body')) {
                    $form.trigger("submit");
                } else {
                    $button.trigger('click');
                }
                // Prevent double-submission
                this.disableButton = true;
                $button.prop("disabled", true);
                if ($button.prop("name")) {
                    $button.after(`<input type="hidden" name="${$button.prop("name")}" value="${$button.val()}" />`);
                }
            } else {
                // Re-add the required attribute to required dependent fields
                $requiredHiddenRecordDependentFields.attr('required', '');
                this.requiredHiddenRecordDependentFieldsCleared = false;
            }
        }
        this.disableButton && $button.prop("disabled", this.requiredHiddenRecordDependentFieldsCleared);
    }
}

export default function createSubmitRecordButtonComponent(el: HTMLElement | JQuery<HTMLElement>) {
    return new SubmitRecordButton($(el));
}
