import { Component } from 'component'
import { initValidationOnField } from 'validation'

/**
 * Radio group component
 */
class RadioGroupComponent extends Component {
  /**
   * Create a new radio group component
   * @param {HTMLElement} element The element to attach the component to
   */
  constructor(element) {
    super(element)
    this.el = $(this.element)

    if (this.el.hasClass("radio-group--required")) {
      initValidationOnField(this.el)
    }
  }
}

export default RadioGroupComponent
