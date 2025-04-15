import { Component } from 'component'

/**
 * Checkbox Component
 */
class CheckboxComponent extends Component {
  /**
   * Create a new checkbox component
   * @param {HTMLElement} element The element to attach the checkbox component to
   */
  constructor(element) {
    super(element)
    this.el = $(this.element)

    this.initCheckbox()
  }

  /**
   * Intializes the checkbox component
   */
  initCheckbox() {
    const inputEl = $(this.el).find('input')
    const id = $(inputEl).attr('id')
    const $revealEl = $(`#${id}-reveal`)

    if ($(inputEl).is(':checked')) {
      this.showRevealElement($revealEl, true)
    }

    $(inputEl).on('change', () => {
      if ($(inputEl).is(':checked')) {
        this.showRevealElement($revealEl, true)
      } else {
        this.showRevealElement($revealEl, false)
      }
    })
  }

  /**
   * Show an element
   * @param {JQuery} $revealEl The element to reveal
   * @param {boolean} bShow Whether to show or hide the element
   */
  showRevealElement($revealEl, bShow) {
    const strCheckboxRevealShowClassName = 'checkbox-reveal--show'

    if (bShow) {
      $revealEl.addClass(strCheckboxRevealShowClassName)
    } else {
      $revealEl.removeClass(strCheckboxRevealShowClassName)
    }
  }
}

export default CheckboxComponent
