import { Component } from 'component'
import 'jquery-ui-sortable-npm'

const BTN_ICON_CLOSE = 'btn-icon-close'
const BTN_ICON_CLOSE_HIDDEN = 'btn-icon-close--hidden'
const SORTABLE_HANDLE = 'sortable__handle'
const SORTABLE_HANDLE_HIDDEN = 'sortable__handle--hidden'
const SORTABLE_ROW = 'sortable__row'

/**
 * Component that allows sorting of data
 */
class SortableComponent extends Component {
  /**
   * Create a new sortable component
   * @param {HTMLElement} element The element to attach the component to
   */
  constructor(element) {
    super(element)
    this.el = $(this.element)
    this.sortableList = this.el.find('.sortable__list')
    this.addBtn = this.el.find('.btn-default')
    this.delBtn = this.el.find(`.${BTN_ICON_CLOSE}`)

    this.initSortable()
  }

  /**
   * Initialize the sortable component
   */
  initSortable() {
    if (this.el.find(`.${SORTABLE_ROW}`).length === 1) {
      this.hideButtons()
    }

    this.sortableList.sortable({
      handle: `.${SORTABLE_HANDLE}`
    })

    this.addBtn.on('click', () => { this.handleClickAdd() })
    this.delBtn.on('click', (ev) => { this.handleClickDelete(ev) })
  }

  /**
   * Handle the click event for the add button
   */
  handleClickAdd() {
    this.el.find(`.${BTN_ICON_CLOSE}`).removeClass(BTN_ICON_CLOSE_HIDDEN)
    this.el.find(`.${SORTABLE_HANDLE}`).removeClass(SORTABLE_HANDLE_HIDDEN)

    const $sortableRows = this.el.find(`.${SORTABLE_ROW}`)
    const $currentSortableRow = $sortableRows.last()
    const $newSortableRow = $currentSortableRow.clone(true)
    const $newInput = $newSortableRow.find('.form-control')
    const $newEnumvalId = $newSortableRow.find('input[name="enumval_id"]')
    const strNamePrefix = $newInput.attr('name')

    this.countInputIdentifier = this.uniqueID()

    $newInput.attr('name', strNamePrefix)
    $newInput.attr('id', `${strNamePrefix}_${this.countInputIdentifier}`)
    $newInput.val('')
    $newInput.removeAttr('value')

    $newEnumvalId.val('')
    $newEnumvalId.removeAttr('value')

    $currentSortableRow.after($newSortableRow)

    this.sortableList.sortable('refresh')
  }

  /**
   * Handle the click event for the delete button
   * @param {JQuery.Event} ev The event object
   */
  handleClickDelete(ev) {
    const target = $(ev.currentTarget)

    target.parent().remove()

    if (this.el.find(`.${SORTABLE_ROW}`).length === 1) {
      this.hideButtons()
    }
  }

  /**
   * Create a random unique ID
   * @returns {number} A unique ID
   */
  uniqueID() {
    return Math.floor(Math.random() * Date.now())
  }

  /**
   * Hide the buttons in the sortable component
   */
  hideButtons() {
    this.el.find(`.${BTN_ICON_CLOSE}`).addClass(BTN_ICON_CLOSE_HIDDEN)
    this.el.find(`.${SORTABLE_HANDLE}`).addClass(SORTABLE_HANDLE_HIDDEN)
  }
}

export default SortableComponent
