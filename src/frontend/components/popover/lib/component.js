import { Component } from 'component'

class PopoverComponent extends Component {
  constructor(element)  {
      super(element)
      this.el = $(this.element)
      this.button = this.el.find('.popover__btn')
      this.popover = this.el.find('.popover')
      this.arrow = this.el.find('.arrow')
      this.strShowClassName = 'show'

      this.initPopover(this.button)
  }

  initPopover(button) {
      if (!button) {
          return
      }

      this.popover.removeClass(this.strShowClassName)
      this.arrow.removeClass(this.strShowClassName)
      button.on('click keydown', (ev) => {
        if (ev.type === 'click' || (ev.type === 'keydown' && (ev.which === 13 || ev.which === 32))) {
          ev.preventDefault()
          this.handleClick(ev) }
        })
  }

  handleClick(ev) {
    const target = $(ev.target)
    this.togglePopover()
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

  togglePopover() {
    
    if (this.popover.hasClass(this.strShowClassName)) {
      this.popover.removeClass(this.strShowClassName)
      this.arrow.removeClass(this.strShowClassName)
    } else {
      this.popover.addClass(this.strShowClassName)
      this.arrow.addClass(this.strShowClassName)
    }
  }
}

export default PopoverComponent
