import { clearSavedFormValues } from "./common";

/**
 * Create a cancel button that navigates away from the page
 * This component will navigate away to the parameter defined in the data-href attribute, or will navigate back
 * @param el The button element
 */
export default function createCancelButton(el: HTMLElement | JQuery<HTMLElement>) {
    const $el = $(el);
    if ($el[0].tagName !== 'BUTTON') return;
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