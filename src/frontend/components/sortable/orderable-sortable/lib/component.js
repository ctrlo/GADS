import { Component } from 'component';

/**
 * Class representing an OrderableSortable component.
 * This component allows users to sort items in a list based on their input values.
 */
class OrderableSortableComponent extends Component {
    /**
     * Creates an instance of OrderableSortableComponent.
     * @param {HTMLElement} element The HTML element where the sortable component will be initialized
     */
    constructor(element) {
        super(element);
        this.el = $(this.element);
        this.selectElement = this.el.find('.select__menu-item');

        this.initSortable();
    }

    /**
     * Initializes the sortable component with event listeners.
     */
    initSortable() {
        this.selectElement.on('click', (ev) => { this.handleOrder(ev); });
    }

    /**
     * Handles the click event for ordering items.
     * @param {JQuery.ClickEvent} ev The click event triggered by the user.
     */
    handleOrder(ev) {
        const target = $(ev.currentTarget);

        if (target.data('value') === 2) {
            this.orderRows(true);
        } else if (target.data('value') === 3) {
            this.orderRows(false);
        }
    }

    /**
     * Order rows based on the input values of the sortable items.
     * @param {boolean} ascending Whether to order rows in ascending or descending order.
     */
    orderRows(ascending) {
        const items = $('.sortable__list').children('.sortable__row')
            .sort(function (a, b) {
                const vA = $('.input > .input__field > .form-control', a).val();
                const vB = $('.input > .input__field > .form-control', b).val();
                if (ascending) {
                    return (vA < vB) ? -1 : (vA > vB) ? 1 : 0;
                } else {
                    return (vA > vB) ? -1 : (vA < vB) ? 1 : 0;
                }
            });
        $('.sortable__list').append(items);
    }
}

export default OrderableSortableComponent;
