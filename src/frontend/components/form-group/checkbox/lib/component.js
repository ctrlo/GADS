import { Component } from 'component'

/**
 * Checkbox Component
 */
class CheckboxComponent extends Component {
  /**
   * Create a new Checkbox
   * @param {HTMLElement} element The checkbox element
   */
  constructor(element)  {
    super(element)
    this.el = $(this.element)

    this.initCheckbox()
  }

  /**
   * Intialize the checkbox
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
   * Show or hide an element based on a checkbox
   * @param {JQuery<HTMLElement>} $revealEl The element to show or hide
   * @param {boolean} bShow Whether to show or hide the element (true to show, false to hide)
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
