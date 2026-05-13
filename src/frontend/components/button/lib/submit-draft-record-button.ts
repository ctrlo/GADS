import { clearSavedFormValues } from './common';

/**
 * Create a submit draft record button
 * @param {JQuery<HTMLElement>} element The button element
 */
export default function createSubmitDraftRecordButton(element: JQuery<HTMLElement>) {
    element.on('click', async (ev: JQuery.ClickEvent) => {
        const $button = $(ev.target).closest('button');
        const $form = $button.closest('form');

        // Remove the required attribute from hidden required dependent fields
        $form.find('.form-group *[aria-required]').removeAttr('required');
        clearSavedFormValues();
    });
}
