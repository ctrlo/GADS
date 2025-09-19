import { Component } from 'component';
import 'jquery-ui-sortable-npm';

const BTN_ICON_CLOSE = 'btn-icon-close';
const BTN_ICON_CLOSE_HIDDEN = 'btn-icon-close--hidden';
const SORTABLE_HANDLE = 'sortable__handle';
const SORTABLE_HANDLE_HIDDEN = 'sortable__handle--hidden';
const SORTABLE_ROW = 'sortable__row';

/**
 * Class representing a Sortable component.
 * This component allows users to add, delete, and reorder items in a sortable list.
 */
class SortableComponent extends Component {
    /**
     * Creates an instance of SortableComponent.
     * @param {HTMLElement} element The HTML element where the sortable component will be initialized
     */
    constructor(element) {
        super(element);
        this.el = $(this.element);
        this.sortableList = this.el.find('.sortable__list');
        this.addBtn = this.el.find('.btn-primary');
        this.delBtn = this.el.find(`.${BTN_ICON_CLOSE}`);
        this.dragHandle = this.el.find(`.${SORTABLE_HANDLE}`);

        this.initSortable();
    }

    /**
     * Initializes the sortable component with event listeners.
     */
    initSortable() {
        if (this.el.find(`.${SORTABLE_ROW}`).length === 1) {
            this.hideButtons();
        }

        this.sortableList.sortable({
            handle: `.${SORTABLE_HANDLE}`
        });

        this.addBtn.on('click', () => { this.handleClickAdd(); });
        this.delBtn.on('click', (ev) => { this.handleClickDelete(ev); });
    }

    /**
     * Handles the click event for adding a new sortable row.
     */
    handleClickAdd() {
        this.el.find(`.${BTN_ICON_CLOSE}`).removeClass(BTN_ICON_CLOSE_HIDDEN);
        this.el.find(`.${SORTABLE_HANDLE}`).removeClass(SORTABLE_HANDLE_HIDDEN);

        const $sortableRows = this.el.find(`.${SORTABLE_ROW}`);
        const $currentSortableRow = $sortableRows.last();
        const $newSortableRow = $currentSortableRow.clone(true);
        const $newInput = $newSortableRow.find('.form-control');
        const $newEnumvalId = $newSortableRow.find('input[name="enumval_id"]');
        const strNamePrefix = $newInput.attr('name');

        this.countInputIdentifier = this.uniqueID();

        $newInput.attr('name', strNamePrefix);
        $newInput.attr('id', `${strNamePrefix}_${this.countInputIdentifier}`);
        $newInput.val('');
        $newInput.removeAttr('value');

        $newEnumvalId.val('');
        $newEnumvalId.removeAttr('value');

        $currentSortableRow.after($newSortableRow);

        this.sortableList.sortable('refresh');
    }

    /**
     * Handles the click event for deleting a sortable row.
     * @param {JQuery.ClickEvent} ev The click event triggered by the user.
     */
    handleClickDelete(ev) {
        const target = $(ev.currentTarget);

        target.parent().remove();

        if (this.el.find(`.${SORTABLE_ROW}`).length === 1) {
            this.hideButtons();
        }
    }

    /**
     * Generates a unique identifier based on the current time.
     * @returns {number} A unique identifier based on the current time.
     */
    uniqueID() {
        return Math.floor(Math.random() * Date.now());
    }

    /**
     * Hides the delete buttons and drag handles when there is only one sortable row.
     */
    hideButtons() {
        this.el.find(`.${BTN_ICON_CLOSE}`).addClass(BTN_ICON_CLOSE_HIDDEN);
        this.el.find(`.${SORTABLE_HANDLE}`).addClass(SORTABLE_HANDLE_HIDDEN);
    }
}

export default SortableComponent;
