import gadsStorage from "util/gadsStorage";

export async function clearSavedFormValues($form: JQuery<HTMLElement>) {
    if (!$form || $form.length === 0) return;
    const layout = layoutId();
    const record = recordId();
    const ls = storage();
    let item = await ls.getItem(table_key());

    if (item) await ls.removeItem(`linkspace-record-change-${layout}-${record}`);
    await Promise.all($form.find(".linkspace-field").map(async (_, el) => {
        const field_id = $(el).data("column-id");
        item = await ls.getItem(`linkspace-column-${field_id}-${layout}-${record}`);
        if (item) gadsStorage.removeItem(`linkspace-column-${field_id}-${layout}-${record}`);
    }));
}

export function layoutId() {
    return $('body').data('layout-identifier');
}

export function recordId() {
    return isNaN(parseInt(location.pathname.split('/').pop())) ? 0 : parseInt(location.pathname.split('/').pop());
}

export function table_key() {
    return `linkspace-record-change-${layoutId()}-${recordId()}`;
}

export function storage() {
    return location.hostname === 'localhost' || window.test ? localStorage : gadsStorage;
}
