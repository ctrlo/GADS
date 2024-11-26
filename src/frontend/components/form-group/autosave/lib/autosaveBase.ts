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
        const id = location.pathname.split('/').pop();
        return isNaN(parseInt(id)) ? 0 : id;
    }

    get storage() {
        return gadsStorage;
    }

    columnKey($field:JQuery) {
        return `linkspace-column-${$field.data('column-id')}-${this.layoutId}-${this.recordId}`;
    }

    abstract initAutosave(): void;
}