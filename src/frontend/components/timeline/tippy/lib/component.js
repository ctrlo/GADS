import { Component } from 'component'
import tippy from 'tippy.js'

/**
 * Tippy Component
 */
class TippyComponent extends Component {
  /**
   * Create a new Tippy Component
   * @param {HTMLElement} element The element to attach the component to
   */
  constructor(element) {
    super(element)
    this.el = $(this.element)
  }

  /**
   * Initialize the tippy component
   * @param {HTMLElement} wrapperEl The wrapper element to append the tippy to
   */
  initTippy(wrapperEl) {
    tippy(this.element, {
      theme: 'light',
      allowHTML: true,
      interactive: true,
      appendTo: wrapperEl,
    })
  }
}

export default TippyComponent
