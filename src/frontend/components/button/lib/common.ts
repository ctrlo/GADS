import StorageProvider from "util/storageProvider";

/**
 * Clear all saved form values for the current record
 */
export async function clearSavedFormValues() {
    const ls = storage();
    const item = await ls.getItem(table_key());

    if (item) ls.clear();
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
    return new StorageProvider(table_key());
}