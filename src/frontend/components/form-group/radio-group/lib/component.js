import { Component } from 'component';
import { initValidationOnField } from 'validation';

class RadioGroupComponent extends Component {
    constructor(element)  {
      super(element);
      this.el = $(this.element);

      if (this.el.hasClass("radio-group--required")) {
        initValidationOnField(this.el);
      }
    }
}

export default RadioGroupComponent;
