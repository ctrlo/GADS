import { Component } from 'component';
import '@lol768/jquery-querybuilder-no-eval';

declare global {
    // Global interface for the window object to include the UpdatePeopleFilter method.
    interface Window {
        /**
         * Update the people filter based on the current query builder state.
         * @param builder The jQuery QueryBuilder instance.
         * @param ev The event that triggered the update.
         */
        UpdatePeopleFilter: (builder: JQuery, ev: Event | JQuery.Event) => void;
    }

    /**
     * jQuery interface extension to include queryBuilder methods.
     */
    interface JQuery<TElement = HTMLElement> {
        /**
         * Create or initialize a query builder with the given filters.
         * @param filters The filter settings to initialize the query builder.
         * @returns A jQuery object for chaining.
         */
        queryBuilder(filters: any): JQuery<TElement>;
        /**
         * Perform a method call on the query builder.
         * @param method The method to call on the query builder.
         * @param args The arguments to pass to the method.
         * @returns The result of the method call.
         */
        queryBuilder(method: string, ...args: any[]): any;
    }
}

/**
 * Interface for filter settings used in the query builder.
 */
interface FilterSettings {
    /**
     * Optional filter for items that are not done.
     * @type {any}
     */
    filterNotDone?: any;
    /**
     * Settings for the query builder filters.
     * @type {any}
     */
    filters: any;
    /**
     * List of operators available for the query builder.
     * @type {string[]}
     */
    operators: string[];
    /**
     * Whether to allow empty values in the query builder.
     * @type {boolean}
     */
    allow_empty: boolean;
}

/**
 * Component for the people filter form group.
 */
class PeopleFilterComponent extends Component {
    /**
     * Create a new PeopleFilterComponent.
     * @param {HTMLElement} element The HTML element for the people filter component.
     */
    constructor(public element: HTMLElement) {
        super(element);
        this.init();
    }

    /**
     * Initialize the people filter component.
     */
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
            console.error('Error:', e);
        }
    }
}

export default PeopleFilterComponent;
