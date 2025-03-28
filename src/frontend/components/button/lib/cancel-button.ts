import { clearSavedFormValues } from "./common";

/**
 * Create a cancel button
 * @param el The element to attach the event handler to
 */
export default function createCancelButton(el: HTMLElement | JQuery<HTMLElement>) {
    const $el = $(el);
    // If the element is not a button, do nothing
    if ($el[0].tagName !== 'BUTTON') return;
    // If the element is already a cancel button, do nothing
    if ($el.data('cancel-button') === "true") return;
    $el.data('cancel-button', "true");
    $el.on('click', async () => {
        const href = $el.data('href');
        await clearSavedFormValues();
        if (href)
            window.location.href = href;
        else
            window.history.back();
    });
}