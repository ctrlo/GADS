import { Component } from 'component'
import { initValidationOnField } from 'validation'

/**
 * Radio Group Component
 */
class RadioGroupComponent extends Component {
  /**
   * Create a Radio Group Component
   * @param {HTMLElement} element The element to create the component on
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
