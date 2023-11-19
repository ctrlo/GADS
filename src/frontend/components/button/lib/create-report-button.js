import { Component } from "component";
import { validateRequiredFields } from "validation";
import { stopPropagation } from "../../util/common";

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
   * Check the report form and submit if valid
   * @param {jQuery.ClickEvent} ev click event
   */
  submitReport(ev) {
    const $button = $(ev.target).closest('button');
    const $form = $button.closest("form");

    if (!this.canSubmitRecordForm) {
      stopPropagation(ev);

      const isValid = validateRequiredFields($form);

      if (isValid) {
        this.canSubmitRecordForm = true;
        this.submit($button);
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
