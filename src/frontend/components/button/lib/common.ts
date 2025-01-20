import gadsStorage from "util/gadsStorage";

/**
 * Clear all saved form values for the current record
 * @param $form The form to clear the data for
 */
export async function clearSavedFormValues($form: JQuery<HTMLElement>) {
    if (!$form || $form.length === 0) return;
    const layout = layoutId();
    const record = recordId();
    const ls = storage();
    const item = await ls.getItem(table_key());

    if (item) ls.removeItem(`linkspace-record-change-${layout}-${record}`);
    await Promise.all($form.find(".linkspace-field").map(async (_, el) => {
        const field_id = $(el).data("column-id");
        const item = await gadsStorage.getItem(`linkspace-column-${field_id}-${layout}-${record}`);
        if (item) gadsStorage.removeItem(`linkspace-column-${field_id}-${layout}-${record}`);
    }));
}

/**
 * Get the layout identifier from the body data
 * @returns The layout identifier
 */
export function layoutId() {
    return $('body').data('layout-identifier');
}

/**
 * Get the record identifier from the body data
 * @returns The record identifier
 */
export function recordId() {
    return $('body').find('.form-edit').data('current-id') || 0;
}

/**
 * Get the key for the table used for saving form values
 * @returns The key for the table
 */
export function table_key() {
    return `linkspace-record-change-${layoutId()}-${recordId()}`;
}

/**
 * Get the storage object - this originally was used in debugging to allow for the storage object to be mocked
 * @returns The storage object
 */
export function storage() {
    return gadsStorage;
}