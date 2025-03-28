import { Component } from "component";
import StorageProvider from "util/storageProvider";

/**
 * Base class for autosave
 */
export default abstract class AutosaveBase extends Component {
    /**
     * Creates a new autosave component
     * @param element The element to attach the autosave functionality to
     */
    constructor(element: HTMLElement) {
        super(element);
        this.initAutosave();
    }

    /**
     * The layout identifier of the current form
     */
    get layoutId() {
        return $('body').data('layout-identifier');
    }

    /**
     * The record identifier of the current form
     */
    get recordId() {
        return $('body').find('.form-edit').data('current-id') || 0;
    }

    /**
     * The storage object to use for autosave - this is a variable to allow for mocking in testing
     */
    get storage() {
        return new StorageProvider(`linkspace-record-change-${this.layoutId}-${this.recordId}`);
    }

    /**
     * The key to use for storing the autosave data
     */
    get table_key() {
        return `linkspace-record-change-${this.layoutId}-${this.recordId}`;
    }

    /**
     * Get the key to use for storing the autosave data for a given field
     * @param $field The field to get the column key for
     * @returns The key to use for storing the autosave data for the given field
     */
    columnKey($field: JQuery) {
        return `linkspace-column-${$field.data('column-id')}-${this.layoutId}-${this.recordId}`;
    }

    /**
     * Initialize the autosave functionality - this is implemented in the child classes
     */
    abstract initAutosave(): void;
}