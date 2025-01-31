import { Component } from "component";
import gadsStorage from "util/gadsStorage";

class AlertComponent extends Component {
    $el: JQuery<HTMLElement>;

    constructor(element: HTMLElement) {
        super(element);
        this.$el = $(element);
        if(this.recordId === undefined) return;
        this.clearData();
    }
    
    /**
     * Clear the data stored in the local storage for the record once it has been saved
     */
    async clearData() {
        const layout = this.layoutId;
        const record = this.recordId;
        const ls = this.storage;
        const item = await ls.getItem(this.table_key);

        if (item) {
            ls.removeItem(this.table_key);
            const len = ls.length;
            for (let i = 0; i < len; i++) {
                const key = ls.key(i);
                if (key && key.startsWith(`linkspace-column`) && key.endsWith(`${layout}-${record}`)) {
                    ls.removeItem(key);
                }
            }
        }
    }

    /**
    * Get the layout identifier from the body data
    * @returns The layout identifier
    */
    get layoutId() {
        return $('body').data('layout-identifier');
    }

    /**
     * Get the record identifier from the body data
     * @returns The record identifier
     */
    get recordId() {
        return this.$el.data('record-id');
    }

    /**
     * Get the key for the table used for saving form values
     * @returns The key for the table
     */
    get table_key() {
        return `linkspace-record-change-${this.layoutId}-${this.recordId}`;
    }

    /**
     * Get the storage object - this originally was used in debugging to allow for the storage object to be mocked
     * @returns The storage object
     */
    get storage() {
        return gadsStorage;
    }
}

export default AlertComponent;