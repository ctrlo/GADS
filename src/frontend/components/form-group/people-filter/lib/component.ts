/// <reference path="../../common/querybuilder.d.ts" />;

import { Component } from "component";
import "@lol768/jquery-querybuilder-no-eval";

class PeopleFilterComponent extends Component {

    constructor(element: HTMLElement) {
        super(element);
        console.log("PeopleFilterComponent", element);
        this.init();
    }

    init() {
        // filters should come from B64 encoded JSON in the data attribute - this is to ensure the naming is kept consistent within a system as the names can be changed
        const data = atob($(this.element).data('filters'));
        console.log("data", data);
        const filters = JSON.parse(data);
        const settings = { filters: filters, operators: ['equal', 'not_equal', 'contains', 'not_contains', 'begins_with', 'ends_with', 'is_empty', 'is_not_empty'] };
        $(this.element).queryBuilder(settings);
    }
}

export default PeopleFilterComponent;