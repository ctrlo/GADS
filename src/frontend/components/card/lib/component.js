import { Component } from 'component';
import 'bootstrap';

/**
 * Creates an expandable card component.
 */
class ExpandableCardComponent extends Component {

    /**
     * Creates an instance of ExpandableCardComponent.
     * @param {HTMLElement} element The HTML element to attach the component to.
     */
    constructor(element) {
        super(element);
        this.$el = $(this.element);
        this.$contentBlock = this.$el.closest('.content-block');

        this.initExpandableCard();

        if (this.$el.hasClass('card--topic')) {
            this.initTopicCard();
        }
    }

    /**
     * Initializes the expandable card functionality.
     */
    initExpandableCard() {
        const $collapsibleElm = this.$el.find('.collapse');
        const $btnEdit = this.$el.find('.btn-js-edit');
        const $btnView = this.$el.find('.btn-js-view');
        const $btnCancel = this.$contentBlock.find('.btn-js-cancel');
        const $recordPopup = this.$el.find('.record-popup');

        $btnEdit.on('click', () => {
            this.$contentBlock.addClass('content-block--edit');
            this.$el.addClass('card--edit');
            $collapsibleElm.collapse('show');
            $(window).on('beforeunload', (ev) => this.confirmOnPageExit(ev));
        });

        $btnView.on('click', () => {
            this.$el.removeClass('card--edit');
            if (this.canRemoveEditClass()) this.$contentBlock.removeClass('content-block--edit');
            $(window).off('beforeunload');
        });

        $btnCancel.on('click', () => {
            this.$contentBlock.find('.card--edit').removeClass('card--edit');
            this.$contentBlock.removeClass('content-block--edit');
            $(window).off('beforeunload');
        });

        // Adjust column widths of datatables when collapsible element is expanded
        $collapsibleElm.on('shown.bs.collapse', () => {
            if ($.fn.dataTable) {
                $($.fn.dataTable.tables(true)).DataTable()
                    .columns.adjust();
                this.clearupStyling();
            }
        });

        $(window).on('resize', () => {
            if ($.fn.dataTable) {
                $($.fn.dataTable.tables(true)).DataTable()
                    .columns.adjust();
                this.clearupStyling();
            }
        });

        $recordPopup.each((i, el) => {
            import(/* webpackChunkName: "record-popup" */ '../../record-popup/lib/component')
                .then(({ default: RecordPopupComponent }) =>
                    new RecordPopupComponent(el)
                );
        });
    }

    /**
     * Initializes the topic card functionality.
     */
    initTopicCard() {
        // Now that fields are shown/hidden on page load, for each topic check
        // whether it has zero displayed fields, in which case hide the whole
        // topic (this also happens on field value change dynamically when a user
        // edits the page).
        // This applies to all of: historical view, main record view page, and main
        // record edit page. Use display:none parameter rather than visibility,
        // as fields will not be visible if view-mode is used in a normal record,
        // and also check .table-fields as historical view will not include any
        // of the linkspace-field fields
        if (!this.$el.find('.list--fields').find('ul li')
            .filter(function () {
                return $(this).css('display') != 'none';
            }).length && !this.$el.find('.linkspace-field').filter(function () {
            return $(this).css('display') != 'none';
        }).length) {
            this.$el.hide();
        }
    }

    /**
     * Checks if the edit class can be removed from the content block.
     * @returns {boolean} True if the edit class can be removed, false otherwise.
     */
    canRemoveEditClass() {
        return !this.$contentBlock.find('.card--edit').length;
    }

    confirmOnPageExit = function (ev) {
        ev = ev || window.event;
        const message = 'Please note that any changes will be lost.';
        if (ev) {
            ev.returnValue = message;
        }
        return message;
    };

    /**
     * In order to ensure headers on the view filter tables are the correct width, we need to remove any styling that has been added to the header elements.
     * And for some reason, using JQuery and DataTables, the styling is not reset as we expect it to be.
     */
    clearupStyling() {
        const tables = $('.table-toggle');
        tables.removeAttr('style');
        const headers = $('.dt-scroll-headInner');
        headers.removeAttr('style');
    }
}

export default ExpandableCardComponent;
