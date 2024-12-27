import { Component } from "component";
import gadsStorage from "util/gadsStorage";

export default abstract class AutosaveBase extends Component {
    constructor(element: HTMLElement) {
        super(element);
        this.initAutosave();
    }

    get isClone() {
        return location.search.includes('from');
    }

    get layoutId() {
        return $('body').data('layout-identifier');
    }

    get recordId() {
        return $('body').find('.form-edit').data('current-id') || 0;
    }

    get storage() {
        return gadsStorage;
    }

    get table_key() {
        return `linkspace-record-change-${this.layoutId}-${this.recordId}`;
    }

    columnKey($field: JQuery) {
        return `linkspace-column-${$field.data('column-id')}-${this.layoutId}-${this.recordId}`;
    }

    abstract initAutosave(): void;
}