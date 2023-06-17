import { Component } from 'component'
import SelectComponent from '../../select/lib/component'
import initDateField from 'components/datepicker/lib/helper'

const SELECT_PLACEHOLDER = 'select__placeholder'
const SELECT_MENU_ITEM_ACTIVE = 'select__menu-item--active'

class MultipleSelectComponent extends Component {
    constructor(element)  {
        super(element)
        this.el = $(this.element)
        this.multipleSelectList = this.el.find('.multiple-select__list')
        this.delBtn = this.el.find('.btn-delete')
        this.addBtn = this.el.find('.btn-add-link')
        this.countSelect = 1

        this.initMultipleSelect(this.el)
    }

    initMultipleSelect() {
        if (!this.multipleSelectList) {
            return
        }

        this.el.find('.multiple-select__row').each((i, row) => {
          this.handleDeleteButtonVisibility(row)

          $(row).find('input[type="hidden"]').on('change', (ev) => this.handleDeleteButtonVisibility(row))
        })

        this.delBtn.on('click', (ev) => { this.handleClickDelete(ev) } )
        this.addBtn.on('click', (ev) => { this.handleClick(ev) } )
    }

    handleDeleteButtonVisibility(row) {
      const delBtn = $(row).find('.btn-delete')
      const rowInputs = $(row).find('input[type="hidden"]')

      delBtn.addClass('btn-delete--hidden')

      rowInputs.each((i, rowInput) => {
        if ($(rowInput).val().length) {
          delBtn.removeClass('btn-delete--hidden')
        }
      })
    }

    handleClick(ev) {
      this.el.find('.btn-delete').removeClass('btn-delete--hidden')

      const $lastMultipleSelectRow = this.el.find('.multiple-select__row').last()
      const $newMultipleSelectRow = $lastMultipleSelectRow.clone()
      const $selectElmsInNewRow = $newMultipleSelectRow.find('.select')
      const $dateElmsInNewRow = $newMultipleSelectRow.find('.input--datepicker').find('.form-control')

      this.countSelect += 1

      // Change the id's of the select elements in the new row
      $selectElmsInNewRow.each( (i, selectEl) => {
        const $newLabel = $(selectEl).find('.select__label > label')
        $newLabel.attr('for', `${$newLabel.attr('for')}-${this.countSelect}` )
        $newLabel.attr('id', `${$newLabel.attr('id')}-${this.countSelect}` )

        const $newButton = $(selectEl).find('.select__toggle')
        $newButton.attr('id', `${$newButton.attr('id')}-${this.countSelect}` )

        const $newInput = $(selectEl).find('input[type="hidden"]')
        $newInput.attr('id', `${$newInput.attr('id')}-${this.countSelect}` )

        const $selectMenu = $(selectEl).find('.select__menu')
        $selectMenu.attr('aria-labelledby', `${$selectMenu.attr('aria-labelledby')}-${this.countSelect}`)

        // Bind events to the new select element
        const newSelectComponent = new SelectComponent(selectEl)
        newSelectComponent.initSelect()
        newSelectComponent.resetSelect()
  
      })

      $dateElmsInNewRow.each( (i, dateEl) => {
        initDateField($(dateEl))
      })

      // Bind click event to new delete button
      const $delBtn = $newMultipleSelectRow.find('.btn-delete')
      $delBtn.on('click', (ev) => { this.handleClickDelete(ev) } )

      $newMultipleSelectRow.appendTo(this.multipleSelectList)
    }

    handleClickDelete(ev) {
      const multipleSelectArray = this.multipleSelectList.find('> .multiple-select__row')
      
      if (multipleSelectArray.length === 1) {
        this.resetRow(multipleSelectArray[0])
      } else {
        const target = $(ev.currentTarget)
        target.closest('.multiple-select__row').remove()

        const newMultipleSelectArray = this.multipleSelectList.find('> .multiple-select__row')

        if (newMultipleSelectArray.length === 1) {
          this.handleDeleteButtonVisibility(newMultipleSelectArray[0])
        }
      }
    }

    resetRow(row) {
      const rowInputs = $(row).find('input[type="hidden"]')

      rowInputs.each((i, input) => {
        const placeholder = input.placeholder
        const select = $(input).closest('.select')
        const toggleButton = select.find('.select__toggle')
        const options = select.find('.select__menu-item')

        toggleButton.find('span').html(placeholder)
        toggleButton.find('span').addClass(SELECT_PLACEHOLDER)
        
        options.removeClass(SELECT_MENU_ITEM_ACTIVE)
        options.attr('aria-selected', false)

        $(input).removeAttr('value')
        $(input).removeAttr('data-restore-value')
      })

      this.handleDeleteButtonVisibility(row)

    }
}

export default MultipleSelectComponent
