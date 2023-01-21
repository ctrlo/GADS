import ModalComponent from '../../../lib/component'
import { getFieldValues } from "get-field-values"
import { guid as Guid } from "guid"
import { initializeRegisteredComponents } from 'component'
import { validateRadioGroup, validateCheckboxGroup } from 'validation'
import SelectWidgetComponent from '../../../../form-group/select-widget/lib/component'

class CurvalModalComponent extends ModalComponent {
  constructor(element)  {
    super(element)
    this.context = undefined
    this.initCurvalModal()
  }

  // Initialize the modal
  initCurvalModal() {
    this.setupModal()
    this.setupSubmit()
  }
  
  curvalModalValidationSucceeded(form, values) {
    const form_data = form.serialize()
    const modal_field_ids = form.data("modal-field-ids")
    const col_id = form.data("curval-id")
    const instance_name = form.data("instance-name")
    let guid = form.data("guid")
    const hidden_input = $("<input>").attr({
      type: "hidden",
      name: "field" + col_id,
      value: form_data
    })
    const $formGroup = $("div[data-column-id=" + col_id + "]")
    const valueSelector = $formGroup.data("value-selector")
    const self = this

    if (valueSelector === "noshow") {
      const row_cells = $('<tr class="table-curval-item">', self.context)

      jQuery.map(modal_field_ids, function(element) {
        const control = form.find('[data-column-id="' + element + '"]')
        let value = getFieldValues(control)
        value = values["field" + element]
        value = $("<div />", self.context).text(value).html()
        row_cells.append(
          $('<td class="curval-inner-text">', self.context).append(value)
        )
      })

      const editButton = $(
        `<td>
          <button type="button" class="btn btn-small btn-link btn-js-curval-modal" data-toggle="modal" data-target="#curvalModal" data-layout-id="${col_id}" data-instance-name="${instance_name}">
            <span class="btn__title">Edit</span>
          </button>
          </td>`,
        self.context
      )

      const removeButton = $(
        `<td>
          <button type="button" class="btn btn-small btn-delete btn-js-curval-remove">
            <span class="btn__title">Remove</span>
          </button>
        </td>`,
        self.context
      )

      row_cells.append(editButton.append(hidden_input)).append(removeButton)

      /* Activate remove button in new row */
      initializeRegisteredComponents(row_cells[0])

      if (guid) {
        const hidden = $('input[data-guid="' + guid + '"]', self.context).val(form_data)
        hidden.closest(".table-curval-item").replaceWith(row_cells)
      } else {
        $(`#curval_list_${col_id}`).find("tbody").prepend(row_cells)
      }
    } else {
      const $widget = $formGroup.find(".select-widget").first()
      const multi = $widget.hasClass("multi")
      const required = $widget.hasClass("select-widget--required")
      const $current = $formGroup.find(".current")
      const $currentItems = $current.find("[data-list-item]")

      const $search = $current.find(".search")
      const $answersList = $formGroup.find(".available")

      if (!multi) {
        /* Deselect current selected value */
        $currentItems.attr("hidden", "")
        $answersList.find("li input").prop("checked", false)
      }

      const textValue = jQuery
        .map(modal_field_ids, function(element) {
          const value = values["field" + element]
          return $("<div />")
            .text(value)
            .html()
        })
        .join(", ")

      guid = Guid()
      const id = `field${col_id}_${guid}`
      const deleteButton = multi
        ? '<button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete" title="delete" tabindex="-1">&times;</button>'
        : ""
      
        $search.before(
        `<li data-list-item="${id}"><span class="widget-value__value">${textValue}</span>${deleteButton}</li>`
      ).before(' ') // Ensure space between elements in widget

      const inputType = multi ? "checkbox" : "radio"
      const strRequired = required ?
          `required="required" aria-required="true" aria-errormessage="${$widget.attr('id')}-err"` :
          ``

      $answersList.append(`<li class="answer" role="option">
        <div class="control">
          <div class="${ multi ? "checkbox" : "radio-group__option" }">
            <input ${strRequired} id="${id}" name="field${col_id}" type="${inputType}" value="${form_data}" class="${ multi ? "" : "radio-group__input" }" checked aria-labelledby="${id}_label">
            <label id="${id}_label" for="${id}" class="${ multi ? "" : "radio-group__label" }">
              <span>${textValue}</span>
            </label>
          </div>
        </div>
        <div class="details">
          <button type="button" class="btn btn-small btn-danger btn-js-curval-remove">
            <span class="btn__title">Remove</span>
          </button>
        </div>
      </li>`)

      this.updateWidgetState($widget, multi, required)

      /* Reinitialize widget */
      initializeRegisteredComponents($formGroup[0])
      const selectWidgetComponent = new SelectWidgetComponent($widget[0])
    }

    $(this.element).modal('hide')
  };

  updateWidgetState($widget, multi, required) {
    const $current = $widget.find(".current")
    const $visible = $current.children("[data-list-item]:not([hidden])")

    $current.toggleClass("empty", $visible.length === 0)

    if (required) {
      if (multi) {
        validateCheckboxGroup($widget)
      } else {
        validateRadioGroup($widget)
      }
    }
  }

  curvalModalValidationFailed(form, errorMessage) {
    form
      .find(".alert")
      .text(errorMessage)
      .removeAttr("hidden")
    form
      .parents(".modal-content")
      .get(0)
      .scrollIntoView()
    form.find("button[type=submit]").prop("disabled", false)
  }

  setupModal() {
    const self = this

    this.el.on('show.bs.modal', (ev) => { 
      const button = ev.relatedTarget
      const layout_id = $(button).data("layout-id")
      const instance_name = $(button).data("instance-name")
      const current_id = $(button).data("current-id")
      const hidden = $(button)
        .closest(".table-curval-item")
        .find(`input[name=field${layout_id}]`)
      const form_data = hidden.val()
      const mode = hidden.length ? "edit" : "add"
      const $formGroup = $(button).closest('.form-group')
      let guid

      if ($formGroup.find('.table-curval-group').length) {
        self.context = $formGroup.find('.table-curval-group')
      } else if ($formGroup.find('.select-widget').length) {
        self.context = $formGroup.find('.select-widget')
      }

      if (mode === "edit") {
        guid = hidden.data("guid")
        if (!guid) {
          guid = Guid()
          hidden.attr("data-guid", guid)
        }
      }

      const $m = $(self.element)
      $m.find(".modal-body").text("Loading...")

      const url = current_id
        ? `/record/${current_id}`
        : `/${instance_name}/record/`

      $m.find(".modal-body").load(
        self.getURL(url, layout_id, form_data, $formGroup),
        function() {
          if (mode === "edit") {
            $m.find("form").data("guid", guid);
          }
          initializeRegisteredComponents(self.element)
        }
      )

      $m.on("focus", ".datepicker", function() {
        $(this).datepicker({
          format: $m.attr("data-dateformat-datepicker"),
          autoclose: true
        })
      })
    })
  }

  getURL(url, layout_id, form_data, $formGroup) {
    const devURLs = window.siteConfig && window.siteConfig.urls.curvalTableForm && window.siteConfig.urls.curvalSelectWidgetForm

    if (devURLs) {
      if ($formGroup.data('value-selector') === 'noshow') {
        return window.siteConfig.urls.curvalTableForm
      } else {
        return window.siteConfig.urls.curvalSelectWidgetForm
      }
    } else {
      return `${url}?include_draft&modal=${layout_id}&${form_data}`
    }
  }

  setupSubmit() {
    const self = this

    $(this.element).on("submit", ".curval-edit-form", function(e) {
      e.preventDefault()
      const $form = $(this)
      const form_data = $form.serialize()

      $form.addClass("edit-form--validating")
      $form.find(".alert").attr("hidden", "")

      const devData = window.siteConfig && window.siteConfig.curvalData

      if (devData) {
        self.curvalModalValidationSucceeded($form, devData.values)
      } else {
        $.post(
          $form.attr("action") + "?validate&include_draft&source=" + $form.data("curval-id"),
          form_data,
          function(data) {
            if (data.error === 0) {
              self.curvalModalValidationSucceeded($form, data.values)
            } else {
              const errorMessage =
                data.error === 1 ? data.message : "Oops! Something went wrong."
              self.curvalModalValidationFailed($form, errorMessage)
            }
          },
          "json"
        )
        .fail(function(jqXHR, textstatus, errorthrown) {
          const errorMessage = `Oops! Something went wrong: ${textstatus}: ${errorthrown}`
          self.curvalModalValidationFailed($form, errorMessage);
        })
        .always(function() {
          $form.removeClass("edit-form--validating")
        });
      }
    });
  };
}

export default CurvalModalComponent
