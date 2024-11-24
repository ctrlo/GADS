import { clearSavedFormValues } from "./common";

export default function createCancelButton(el: HTMLElement | JQuery<HTMLElement>) {
    const $el = $(el);
    if ($el[0].tagName !== 'BUTTON') return;
    $el.data('cancel-button', "true");
    $el.on('click', async () => {
        const href = $el.data('href');
        await clearSavedFormValues($el.closest('form'));        
        if (href)
            window.location.href = href;
        else
            window.history.back();
    });
}