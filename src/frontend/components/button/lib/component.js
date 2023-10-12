import { Component } from 'component'

class ButtonComponent extends Component {
  constructor(element)  {
    super(element)
    this.el = $(this.element)
    this.requiredHiddenRecordDependentFieldsCleared = false
    this.canSubmitRecordForm = false
    this.initButton()
  }

  initButton() {
    if (this.el.hasClass('btn-js-calculator')) {
      this.initCalculator()
    }
  }
}

export default ButtonComponent
