import StorageProvider from "util/storageProvider";
import { addAction } from "./handler";
import loadActions from "./actionsLoader";

// Exported to be used in tests - return values are to be used in tests
export const clearAutorecoverAction = async () => {
    // Load the body as a jQuery object
    const $body = $('body');
    // Get the layout identifier from the body data
    const layoutId = $body.data('layout-identifier');
    // If the layout identifier is undefined, return
    if (typeof layoutId == 'undefined') return false;
    // Load the actions object
    const actions = await loadActions();
    // If the actions object is undefined, return
    if (typeof actions == 'undefined') return false;
    // Get the record identifier from the actions object
    const recordId = actions.clear_saved_values;
    // If the record identifier is undefined, return
    if (typeof recordId == 'undefined') return false;
    // Create a table key using the layout identifier and record identifier
    const tableKey = `linkspace-record-change-${layoutId}-${recordId}`;
    // Create a new storage provider
    const storage = new StorageProvider(tableKey);
    // Clear the storage provider
    await storage.clear();
    return true;
}

/**
 * Action handler for when a record is created or updated - only runs outside of a test environment
 */
if (!window.test) addAction(clearAutorecoverAction);
