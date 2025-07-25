import { Component } from 'component';
import StorageProvider from 'util/storageProvider';

/**
 * Base class for autosave/recovery functionality.
 */
export default abstract class AutosaveBase extends Component {
    /**
     * Creates a new autosave component
     * @param {HTMLElement} element The element to attach the autosave functionality to
     */
    constructor(element: HTMLElement) {
        super(element);
        this.initAutosave();
    }

    /**
     * Whether the current form is a clone
     * @returns {boolean} True if the form is a clone, false otherwise
     */
    get isClone(): boolean {
        return !!$('body').find('.form-edit')
            .data('from');
    }

    /**
     * The layout identifier of the current form
     * @returns {string} The layout identifier of the current form
     */
    get layoutId(): string {
        return $('body').data('layout-identifier');
    }

    /**
     * The record identifier of the current form
     * @returns {number} The record identifier of the current form
     */
    get recordId(): number {
        return $('body').find('.form-edit')
            .data('current-id') || 0;
    }

    /**
     * The storage object to use for autosave - this is a variable to allow for mocking in testing
     * @returns {StorageProvider} The storage provider for autosave
     */
    get storage(): StorageProvider {
        return new StorageProvider(`linkspace-record-change-${this.layoutId}-${this.recordId}`);
    }

    /**
     * The key to use for storing the autosave data
     * @returns {string} The key to use for storing the autosave data
     */
    get table_key(): string {
        return `linkspace-record-change-${this.layoutId}-${this.recordId}`;
    }

    /**
     * Get the key to use for storing the autosave data for a given field
     * @param {JQuery<HTMLElement>} $field The field to get the column key for
     * @returns {string} The key to use for storing the autosave data for the given field
     */
    columnKey($field: JQuery<HTMLElement>): string {
        return `linkspace-column-${$field.data('column-id')}-${this.layoutId}-${this.recordId}`;
    }

    /**
     * Initialize the autosave functionality - this is implemented in the child classes
     */
    abstract initAutosave(): void;
}
