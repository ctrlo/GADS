import StorageProvider from "util/storageProvider";
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
    const storage = new StorageProvider(tableKey);
    // Clear the storage
    await storage.clear();
});
