import { Component } from 'component'
import tippy from 'tippy.js'

/**
 * A tippy component
 */
class TippyComponent extends Component {
  /**
   * Create a new tippy component
   * @param {HTMLElement} element The element to attach the tippy component to
   */
  constructor(element) {
    super(element)
    this.el = $(this.element)
  }

  /**
   * Initialize the tippy component
   * @param {*} wrapperEl The element to append the tippy to
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
