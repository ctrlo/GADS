import { Component } from 'component'

/**
 * Orderable Sortable Component
 */
class OrderableSortableComponent extends Component {
  /**
   * Create a new orderable sortable component
   * @param {HTMLElement} element The element to attach the orderable sortable component to
   */
  constructor(element) {
    super(element)
    this.el = $(this.element)
    this.selectElement = this.el.find('.select__menu-item')

    this.initSortable()
  }

  /**
   * Initialize the orderable sortable component
   */
  initSortable() {
    this.selectElement.on("click", (ev) => { this.handleOrder(ev) })
  }

  /**
   * Handle the click of an element
   * @param {JQuery.Event} ev The event object
   */
  handleOrder(ev) {
    const target = $(ev.currentTarget)

    if (target.data("value") === 2) {
      this.orderRows(true)
    } else if (target.data("value") === 3) {
      this.orderRows(false)
    }
  }

  /**
   * Order the rows
   * @param {boolean} ascending Are the rows to be sorted in ascending order (true) or descending order (false)
   */
  orderRows(ascending) {
    const items = $('.sortable__list').children(".sortable__row").sort(function (a, b) {
      const vA = $('.input > .input__field > .form-control', a).val()
      const vB = $('.input > .input__field > .form-control', b).val()
      if (ascending) {
        return (vA < vB) ? -1 : (vA > vB) ? 1 : 0
      } else {
        return (vA > vB) ? -1 : (vA < vB) ? 1 : 0
      }
    })
    $('.sortable__list').append(items)
  }
}

export default OrderableSortableComponent
