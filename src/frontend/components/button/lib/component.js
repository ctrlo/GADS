import { Component } from 'component'
import { validateRequiredFields } from 'validation'

class ButtonComponent extends Component {
  constructor(element)  {
    super(element)
    this.el = $(this.element)
    this.requiredHiddenRecordDependentFieldsCleared = false
    this.canSubmitRecordForm = false
    this.initButton()
  }

  initButton() {
    switch (true) {
      case this.el.hasClass('btn-js-submit-record'):
        this.initSubmitRecord()
        break
      case this.el.hasClass('btn-js-save-view'):
        this.initSaveView()
        break
      case this.el.hasClass('btn-js-show-blank'):
        this.initShowBlank()
        break
      case this.el.hasClass('btn-js-curval-remove'):
        this.initRemoveCurval()
        break
    }

    if (this.el.hasClass('btn-js-remove-unload')) {
      this.initRemoveUnload()
    }

    if (this.el.hasClass('btn-js-calculator')) {
      this.initCalculator()
    }
  }

  initRemoveCurval() {
    this.el.on('click', (ev) => {
      const $btn = $(ev.target)

      if ($btn.closest('.table-curval-group').length) {
        if (confirm("Are you sure want to permanently remove this item?")) {
          const curvalItem=$btn.closest(".table-curval-item");
          const parent = curvalItem.parent();
          curvalItem.remove();
          if(parent && parent.children().length==1) {
            parent.children('.odd').children('.dataTables_empty').show();
          }
        } else {
          ev.preventDefault()
        }
      } else if ($btn.closest('.select-widget').length) {
        const fieldId = $btn.closest(".answer").find("input").prop("id")
        const $current = $btn.closest(".select-widget").find(".current")

        $current.find(`li[data-list-item=${fieldId}]`).remove()
        $btn.closest(".answer").remove()

        const $visible = $current.children("[data-list-item]:not([hidden])")
        $current.toggleClass("empty", $visible.length === 0)
      }
    })
  }

  initShowBlank() {
    this.el.on('click', (ev) => {
      const $button = $(ev.target).closest('.btn-js-show-blank')
      const $buttonTitle = $button.find('.btn__title')[0]
      const showBlankFields = $buttonTitle.innerHTML === "Show blank values"

      $(".list__item--blank").toggle(showBlankFields)

      $buttonTitle.innerHTML = showBlankFields
        ? "Hide blank values"
        : "Show blank values"
    })
  }

  initSubmitRecord() {
    this.el.on('click', (ev) => { this.submitRecord(ev) })
  }

  initSaveView() {
    this.el.on('click', (ev) => { this.saveView(ev) })
  }

  initRemoveUnload() {
    this.el.on('click', (ev) => {
      $(window).off('beforeunload')
    })
  }

  submitRecord(ev) {
    const $button = $(ev.target).closest('button')
    const $form = $button.closest("form")
    const $requiredHiddenRecordDependentFields = $form.find(".form-group[data-has-dependency='1'][style*='display: none'] *[aria-required]")

    if (!this.requiredHiddenRecordDependentFieldsCleared) {
      ev.preventDefault()

      // Remove the required attribute from hidden required dependent fields
      $requiredHiddenRecordDependentFields.removeAttr('required')
      this.requiredHiddenRecordDependentFieldsCleared = true
    }

    if (!this.canSubmitRecordForm) {
      ev.preventDefault()

      const isValid = validateRequiredFields($form)

      if (isValid) {
        this.canSubmitRecordForm = true
        $button.trigger('click')
        // Prevent double-submission
        $button.prop("disabled", true);
        if ($button.prop("name")) {
          $button.after(
            '<input type="hidden" name="' +
              $button.prop("name") +
              '" value="' +
              $button.val() +
              '" />'
          );
        }
      } else {
        // Re-add the required attribute to required dependent fields
        $requiredHiddenRecordDependentFields.attr('required', '')
        this.requiredHiddenRecordDependentFieldsCleared = false
      }
    }
  }

  saveView(ev){
    $(".filter").each((i, el) => {
      if (!$(el).queryBuilder('validate')) ev.preventDefault();
      const res = $(el).queryBuilder('getRules')
      $(el).next('#filter').val(JSON.stringify(res, null, 2))
    })
  }

  getURL(data) {
    const devEndpoint = window.siteConfig && window.siteConfig.urls.treeApi

    if (devEndpoint) {
      return devEndpoint
    } else {
      return `/${data.layoutIdentifier}/tree/${data.columnId}`
    }
  }
}

export default ButtonComponent
