import { Component } from 'component'
import { logging } from 'logging'
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
      case this.el.hasClass('btn-js-report'):
        import(/* webpackChunkName: "create-report-button" */ './create-report-button.js')
          .then(({ default: CreateReportButtonComponent }) => {
            new CreateReportButtonComponent(this.element)
          });
        break
      case this.el.hasClass('btn-js-more-info'):
        import(/* webpackChunkName: "more-info-button" */ './more-info-button.js')
          .then(({ default: MoreInfoButton }) => {
            new MoreInfoButton(this.el)
          });
        break
      case this.el.hasClass('btn-js-delete'):
        this.initDelete()
        break
      case this.el.hasClass('btn-js-submit-field'):
        import(/* webpackChunkName: "submit-field-button" */ "./submit-field-button.js")
            .then(({ default: SubmitFieldButtonComponent }) => {
                new SubmitFieldButtonComponent(this.element);
            });
        break
      case this.el.hasClass('btn-js-add-all-fields'):
        this.initAddAllFields()
        break
      case this.el.hasClass('btn-js-submit-draft-record'):
        this.initSubmitDraftRecord()
        break
      case this.el.hasClass('btn-js-submit-record'):
        this.initSubmitRecord()
        break
      case this.el.hasClass('btn-js-save-view'):
        import(/* webpackChunkName: "save-view-button" */ './save-view-button.js')
            .then(({ default: SaveViewButtonComponent }) => {
              new SaveViewButtonComponent(this.element);
            });
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

  // "Add fields" button on the add/edit view page
  initAddAllFields() {
    this.el.on('click', (ev) => {
      ev.preventDefault()
      const sourceTableId = $(ev.target).data('transferSource')
      const destionationTableId = $(ev.target).data('transferDestination')
      const rows = $(sourceTableId).find('tbody tr')
      import(/* webpackChunkName: "datatable-helper" */ '../../data-table/lib/helper')
        .then(({transferRowToTable})=>{
          rows.each((index, row) => {
            transferRowToTable($(row), sourceTableId, destionationTableId)
          })
        });
    })
  }

  initRemoveCurval() {
    this.el.on('click', (ev) => {
      const $btn = $(ev.target)

      if ($btn.closest('.table-curval-group').length) {
        if (confirm("Are you sure want to permanently remove this item?")) {
          const curvalItem=$btn.closest(".table-curval-item");
          const parent = curvalItem.parent();
          curvalItem.remove();
          if(parent && parent.children().length===1) {
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

  initRemoveUnload() {
    this.el.on('click', () => {
      $(window).off('beforeunload')
    })
  }

  initDelete() {
    this.el.on('click', (ev) => { this.dataToModal(ev) })
  }

  submitDraftRecord(ev) {
    const $button = $(ev.target).closest('button')
    const $form = $button.closest("form")

    // Remove the required attribute from hidden required dependent fields
    $form.find(".form-group *[aria-required]").removeAttr('required')
  }

  submitRecord(ev) {
    const $button = $(ev.target).closest('button');
    const $form = $button.closest("form")
    const $requiredHiddenRecordDependentFields = $form.find(".form-group[data-has-dependency='1'][style*='display: none'] *[aria-required]")
    const $parent = $button.closest('.modal-body')

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
        if($parent.hasClass('modal-body')) {
          $form.submit()
        }else{
          $button.trigger('click')
        }
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
    $button.prop("disabled", this.requiredHiddenRecordDependentFieldsCleared);
  }

  getURL(data) {
    const devEndpoint = window.siteConfig && window.siteConfig.urls.treeApi

    if (devEndpoint) {
      return devEndpoint
    } else {
      return `/${data.layoutIdentifier}/tree/${data.columnId}`
    }
  }

  dataToModal(ev) {
    const $button = $(ev.target).closest('button')
    const title = $button.attr('data-title')
    const id = $button.attr('data-id')
    const target = $button.attr('data-target')
    const toggle = $button.attr('data-toggle')
    const modalTitle = title ? `Delete - ${title}` : 'Delete'
    const $deleteModal = $(document).find(`.modal--delete${target}`)

    try {
      if (!id || !target || !toggle) {
        throw 'Delete button should have data attributes id, toggle and target!'
      } else if ($deleteModal.length === 0) {
        throw `There is no modal with id: ${target}`
      }
    } catch (e) {
      logging.error(e)
      this.el.on('click', function(e) {
        e.stopPropagation()
      });
    }

    $deleteModal.find('.modal-title').text(modalTitle)
    $deleteModal.find('button[type=submit]').val(id)
  }
}

export default ButtonComponent
