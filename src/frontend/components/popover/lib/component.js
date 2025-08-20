import { Component } from 'component';

/**
 * PopoverComponent class to manage the behavior of a popover.
 */
class PopoverComponent extends Component {
    /**
     * Creates an instance of PopoverComponent.
     * @param {HTMLElement} element The parent HTML element for the popover.
     */
    constructor(element) {
        super(element);
        this.el = $(this.element);
        this.button = this.el.find('.popover__btn');
        this.popover = this.el.find('.popover');
        this.arrow = this.el.find('.arrow');
        this.strShowClassName = 'show';

        this.initPopover(this.button);
    }

    /**
     * Initializes the popover by setting up event listeners for click and keydown events.
     * @param {HTMLElement} button The button that triggers the popover.
     */
    initPopover(button) {
        if (!button) {
            return;
        }

        this.popover.removeClass(this.strShowClassName);
        this.arrow.removeClass(this.strShowClassName);
        button.on('click keydown', (ev) => {
            if (ev.type === 'click' || (ev.type === 'keydown' && (ev.which === 13 || ev.which === 32))) {
                ev.preventDefault();
                this.handleClick(ev);
            }
        });
    }

    /**
     * Handles the click event on the popover button.
     * @param {JQuery.ClickEvent} ev The click event object.
     */
    handleClick(ev) {
        this.togglePopover();
        ev.stopPropagation();

    // TODO: add listener to document when clicking outside the popover to close it
    // (disabled for now because it caused errors)
    // $(document).on('click', (ev) => {
    //   if (!$(ev.target).hasClass('popover__btn')
    //       && $(ev.target).parents('.popover-container').length === 0) {
    //       this.togglePopover()
    //       $(document).off('click')
    //   }
    // })
    }

    /**
     * Toggle visibility of the popover and its arrow.
     */
    togglePopover() {

        if (this.popover.hasClass(this.strShowClassName)) {
            this.popover.removeClass(this.strShowClassName);
            this.arrow.removeClass(this.strShowClassName);
        } else {
            this.popover.addClass(this.strShowClassName);
            this.arrow.addClass(this.strShowClassName);
        }
    }
}

export default PopoverComponent;
