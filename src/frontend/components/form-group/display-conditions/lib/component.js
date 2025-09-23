import { Component } from 'component';
import 'jQuery-QueryBuilder';
import 'bootstrap-select';
import { refreshSelects } from 'components/form-group/common/bootstrap-select';

/**
 * Component for managing display conditions in form groups.
 */
class DisplayConditionsComponent extends Component {
    /**
     * Create a new DisplayConditionsComponent.
     * @param {HTMLElement} element The HTML element for the component.
     */
    constructor(element) {
        super(element);
        this.el = $(this.element);
        this.initDisplayConditions();
    }

    /**
     * Initialize the display conditions for the form group.
     */
    initDisplayConditions() {
        const builderData = this.el.data();
        const filters = JSON.parse(atob(builderData.filters));
        if (!filters.length) return;

        refreshSelects(this.el);

        this.el.queryBuilder({
            filters: filters,
            allow_groups: 0,
            operators: [
                { type: 'equal', accept_values: true, apply_to: ['string'] },
                { type: 'contains', accept_values: true, apply_to: ['string'] },
                { type: 'not_equal', accept_values: true, apply_to: ['string'] },
                { type: 'not_contains', accept_values: true, apply_to: ['string'] }
            ]
        });

        if (builderData.filterBase) {
            const data = JSON.parse(atob(builderData.filterBase));
            this.el.queryBuilder('setRules', data);
        }
    }
}

export default DisplayConditionsComponent;
