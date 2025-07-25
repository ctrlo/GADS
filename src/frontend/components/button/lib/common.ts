import StorageProvider from 'util/storageProvider';

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
 * @returns { number } The layout identifier
 */
export function layoutId(): number {
    return $('body').data('layout-identifier');
}

/**
 * Get the record identifier from the body data
 * @returns { number } The record identifier
 */
export function recordId(): number {
    return $('body').find('.form-edit')
        .data('current-id') || 0;
}

/**
 * Get the key for the table used for saving form values
 * @returns {string} The key for the table
 */
export function table_key(): string {
    return `linkspace-record-change-${layoutId()}-${recordId()}`;
}

/**
 * Get the storage object - this originally was used in debugging to allow for the storage object to be mocked
 * @returns { StorageProvider } The storage object
 */
export function storage(): StorageProvider {
    return new StorageProvider(table_key());
}
