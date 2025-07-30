import { Component } from 'component';

/**
 * Component for creating a collapsible section in the UI.
 */
class CollapsibleComponent extends Component {
    /**
     * Creates an instance of CollapsibleComponent.
     * @param {HTMLElement} element The element to be initialized as a collapsible component.
     */
    constructor(element) {
        super(element);
        this.el = $(this.element);
        this.button = this.el.find('.btn-collapsible');
        this.titleCollapsed = this.el.find('.btn__title--collapsed');
        this.titleExpanded = this.el.find('.btn__title--expanded');

        this.initCollapsible(this.button);
    }

    /**
     * Initializes the collapsible component.
     * @param {HTMLElement} button The button element that will toggle the collapsible content.
     */
    initCollapsible(button) {
        if (!button) {
            return;
        }

        this.titleExpanded.addClass('hidden');
        button.click(() => { this.handleClick(); });
    }

    /**
     * Handles the click event on the collapsible button.
     */
    handleClick() {
        this.titleExpanded.toggleClass('hidden');
        this.titleCollapsed.toggleClass('hidden');
    }
}

export default CollapsibleComponent;
