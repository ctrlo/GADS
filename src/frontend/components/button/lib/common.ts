import gadsStorage from "util/gadsStorage";

export async function clearSavedFormValues($form: JQuery<HTMLElement>) {
    if (!$form || $form.length === 0) return;
    const layout = layoutId();
    const record = recordId();
    await Promise.all($form.find(".linkspace-field").map(async (_, el) => {
        const field_id = $(el).data("column-id");
        const item = await gadsStorage.getItem(`linkspace-column-${field_id}-${layout}-${record}`);
        if (item) gadsStorage.removeItem(`linkspace-column-${field_id}-${layout}-${record}`);
    }));
}

export function layoutId() {
    return $('body').data('layout-identifier');
}

export function recordId() {
    return isNaN(parseInt(location.pathname.split('/').pop())) ? 0 : parseInt(location.pathname.split('/').pop());
}

export function storage() {
    return location.hostname === 'localhost' || window.test ? localStorage : gadsStorage;
}