import { Component } from 'component'

/**
 * Collapsible component class
 */
class CollapsibleComponent extends Component {
    /**
     * Create a new collapsible component.
     * @param {HTMLElement} element The element to attach the collapsible component to.
     */
    constructor(element) {
        super(element)
        this.el = $(this.element)
        this.button = this.el.find('.btn-collapsible')
        this.titleCollapsed = this.el.find('.btn__title--collapsed')
        this.titleExpanded = this.el.find('.btn__title--expanded')

        this.initCollapsible(this.button)
    }

    /**
     * Initialize the collapsible component.
     * @param {*} button The button to trigger the collapsible component.
     */
    initCollapsible(button) {
        if (!button) {
            return
        }

        this.titleExpanded.addClass('hidden')
        button.click(() => { this.handleClick() })
    }

    /**
     * Handle the click event on the button.
     */
    handleClick() {
        this.titleExpanded.toggleClass('hidden')
        this.titleCollapsed.toggleClass('hidden')
    }
}

export default CollapsibleComponent
