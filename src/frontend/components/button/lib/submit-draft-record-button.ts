import { BaseButton } from "./base-button";

class SubmitDraftRecordButton extends BaseButton {
    type="btn-js-submit";

    click(ev: JQuery.ClickEvent): void {
        const $button = $(ev.target).closest('button');
        const $form = $button.closest("form");

        // Remove the required attribute from hidden required dependent fields
        $form.find(".form-group *[aria-required]").removeAttr('required');
    }
}

export default function createSubmitDraftRecordButton(element: HTMLElement | JQuery<HTMLElement>) {
    return new SubmitDraftRecordButton($(element));
}
