import { Component } from 'component'
import { initValidationOnField } from 'validation'

class TextareaComponent extends Component {
    constructor(element)  {
      super(element)
      this.el = $(this.element)

      if (this.el.hasClass("textarea--required")) {
        initValidationOnField(this.el)
      }
    }
}

export default TextareaComponent
