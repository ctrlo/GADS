import gadsStorage from "util/gadsStorage";
import { addAction } from "./handler";

/**
 * Action handler for when a record is created or updated
 */

addAction(async () => {
    // Create a reference to the body element as a jQuery object (saves multiple calls to the jQuery function)
    const $body = $('body');
    // Get the layout identifier from the data attribute
    const layoutId = $body.data('layout-identifier');
    // If the layout identifier is undefined, return
    if (typeof layoutId == 'undefined') return;
    // Get the record identifier from the data attribute
    const recordId = $body.data('update-record')
    // If the record identifier is undefined, return
    if (typeof recordId == 'undefined') return;
    // Create a key to identify the record change in the storage
    const tableKey = `linkspace-record-change-${layoutId}-${recordId}`;
    // Get the storage object
    const storage = gadsStorage;
    // Get the item from the storage
    const item = await storage.getItem(tableKey);

    // If the item exists
    if (item) {
        // Remove the item from storage
        storage.removeItem(tableKey);
        // Get the length of the storage
        const len = storage.length;
        // Iterate over the storage
        for (let i = 0; i < len; i++) {
            // Get the key from the storage
            const key = storage.key(i);
            // If the key does not start with 'linkspace-column' and does not end with the layout and record identifier, 
            // skip ahead, this reduces the cyclomatic complexity
            if (!(key && key.startsWith('linkspace-column') && key.endsWith(`-${layoutId}-${recordId}`))) continue;
            // Remove the item from the storage
            storage.removeItem(key);
        }
    }
});
