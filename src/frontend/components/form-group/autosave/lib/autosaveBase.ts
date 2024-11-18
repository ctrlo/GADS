import { Component } from "component";
import gadsStorage from "util/gadsStorage";

export default abstract class AutosaveBase extends Component {
    get test() {
        return location.hostname === 'localhost' || window.test;
    }

    constructor(element: HTMLElement) {
       super(element);
       this.initAutosave();
    }

    get layoutId() {
        return $('body').data('layout-identifier');
    }

    get recordId() {
        const id = location.pathname.split('/').pop();
        return isNaN(parseInt(id)) ? 0 : id;
    }

    get table_key() {
        return `linkspace-record-change-${this.layoutId}-${this.recordId}`;
    }

    get storage() {
        return this.test ? localStorage: gadsStorage;
    }

    columnKey($field:JQuery) {
        return `linkspace-column-${$field.data('column-id')}-${this.layoutId}-${this.recordId}`;
    }

    abstract initAutosave(): void;
}