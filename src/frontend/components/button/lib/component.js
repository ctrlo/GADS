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
    if (this.el.hasClass('btn-js-remove-unload')) {
      this.initRemoveUnload()
    }

    if (this.el.hasClass('btn-js-calculator')) {
      this.initCalculator()
    }
  }

  initRemoveUnload() {
    this.el.on('click', (ev) => {
      $(window).off('beforeunload')
    })
  }
}

export default ButtonComponent
