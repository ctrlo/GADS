/// <reference types="../../common/querybuilder.d.ts" />;

import { Component } from "component";
import "@lol768/jquery-querybuilder-no-eval";

declare global {
    interface Window {
        UpdatePeopleFilter: (builder:JQuery, ev:Event) => void;
    }
}

interface FilterSettings {
    filterNotDone?: any;
    filters: any;
    operators: string[];
    allow_empty: boolean;
}

class PeopleFilterComponent extends Component {
    constructor(public element: HTMLElement) {
        super(element);
        this.init();
    }

    init() {
        const data = atob($(this.element).data('filters'));
        const b64_values = atob($('#people-display').data('filter-base64'));
        //TODO: This is an etymology lab - will rectify when we revisit this task
        if(!data || !b64_values) return;
        const filters = JSON.parse(data);
        const values = JSON.parse(b64_values);
        const settings:FilterSettings = { filters: filters, operators: ['equal', 'not_equal', 'contains', 'not_contains', 'begins_with', 'ends_with', 'is_empty', 'is_not_empty'], allow_empty: true };
        const el = $(this.element);
        el.queryBuilder(settings);
        try {
            Object.keys(values).length > 0 && el.queryBuilder('setRules', values);
            window.UpdatePeopleFilter = (builder, ev) => {
                if (!builder.queryBuilder('validate')) ev.preventDefault();
                const query = builder.queryBuilder('getRules');
                $('#people-display').val(JSON.stringify(query, null, 2));
            }
        } catch(e) {
            console.log("error:", e);
        }
    }
}

export default PeopleFilterComponent;