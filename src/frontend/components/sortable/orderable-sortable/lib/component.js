import { Component } from 'component'

/**
 * Create a component in which items can be ordered and sorted.
 */
class OrderableSortableComponent extends Component {
  /**
   * Create a new Orderable/Sortable component
   * @param {HTMLElement} element The element to attach the component to
   */
  constructor(element) {
    super(element)
    this.el = $(this.element)
    this.selectElement = this.el.find('.select__menu-item')

    this.initSortable()
  }

  /**
   * Initialize the sortable component
   */
  initSortable() {
    this.selectElement.on("click", (ev) => { this.handleOrder(ev) })
  }

  /**
   * Handle the ordering event
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
   * Order the rows in a table
   * @param {boolean} ascending Whether to sort in ascending order
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
