import { Component } from "component";
import "jQuery-QueryBuilder";

declare global {
    interface Window {
        UpdatePeopleFilter: (builder: JQuery, ev: Event | JQuery.Event) => void;
    }

    interface JQuery<TElement = HTMLElement> {
        queryBuilder(filters: any): JQuery<TElement>;
        queryBuilder(method: string, ...args: any[]): any;
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
        const elementData = $(this.element).data('filters');
        const peopleDisplayData = $('#people-display').data('filter-base64');

        if (!elementData || !peopleDisplayData) return;

        const filters = JSON.parse(atob(elementData));
        const values = JSON.parse(atob(peopleDisplayData));
        const settings: FilterSettings = {
            filters: filters,
            operators: [
                'equal', 'not_equal', 'contains', 'not_contains',
                'begins_with', 'ends_with', 'is_empty', 'is_not_empty'
            ],
            allow_empty: true
        };

        const el = $(this.element);
        el.queryBuilder(settings);

        try {
            if (Object.keys(values).length > 0) el.queryBuilder('setRules', values);
            window.UpdatePeopleFilter = (builder, ev) => {
                if (!builder.queryBuilder('validate')) ev.preventDefault();
                const query = builder.queryBuilder('getRules');
                $('#people-display').val(JSON.stringify(query, null, 2));
            };
        } catch (e) {
            console.error("Error:", e);
        }
    }
}

export default PeopleFilterComponent;