import { Component } from 'component'

/**
 * Collapsible component
 */
class CollapsibleComponent extends Component {
    /**
     * Create a collapsible component
     * @param {HTMLElement} element The element to attach the component to
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
     * Initialize the collapsible component
     * @param {JQuery<HTMLButtonElement>} button The button to attach the collapsible to
     */
    initCollapsible(button) {
        if (!button) {
            return
        }

        this.titleExpanded.addClass('hidden')
        button.on("click", () => { this.handleClick() })
    }

    /**
     * Handle the click event
     */
    handleClick() {
        this.titleExpanded.toggleClass('hidden')
        this.titleCollapsed.toggleClass('hidden')
    }
}

export default CollapsibleComponent
