import { Component } from "component";
import { validateRequiredFields } from "validation";
import { logging } from "logging";

/**
 * CreateReportButtonComponent class to create a report submission button component
 * @augments Component
 */
class CreateReportButtonComponent extends Component {
  /**
   * Create a new CreateReportButtonComponent
   * @param {HTMLButtonElement} element button element
   */
  constructor(element) {
    super(element);
    this.el = $(element);
    this.canSubmitRecordForm = false;
    this.initSubmitReport();
  }

  /**
   * Initialise the submit report button
   */
  initSubmitReport() {
    this.el.on('click', (ev) => { this.submitReport(ev) });
  }

  /**
   * Check if at least one checkbox is checked
   * @param {jQuery<HTMLFieldSetElement>} $fieldset fieldset to check
   * @returns {boolean} true if at least one checkbox is checked
   */
  checkForAtLeastOneValue($fieldset) {
    const fields = $fieldset.find("input");

    let result = false;

    fields.each(function () {
      const $this = $(this)
      if ($this.is(":checked") || this.checked) {
        result = true;
      }
    });

    return result;
  }

  /**
   * Check the report form and submit if valid
   * @param {jQuery.ClickEvent} ev click event
   */
  submitReport(ev) {
    const $button = $(ev.target).closest('button');
    const $form = $button.closest("form#myform");
    const $fieldset = $(".fieldset--report");
    const checked = this.checkForAtLeastOneValue($fieldset);

    if (!this.canSubmitRecordForm) {
      ev.preventDefault();

      const isValid = validateRequiredFields($form);

      if (isValid && checked) {
        this.canSubmitRecordForm = true;
        this.submit($button);
      } else if (!checked) {
        $(".alert__no__select").show();
      }
    }
  }

  /**
   * Submit the form
   * @param {jQuery<HTMLButtonElement>} $button form to submit
   */
  submit($button) {
    $button.trigger("click");
    $button.prop("disabled", true);
  }
}

export default CreateReportButtonComponent;
