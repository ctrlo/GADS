//TODO: refactor this into smaller components
import { Component } from "component";
import { validateRequiredFields } from "validation";
import { logging } from "../../../test/logging";

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
    this.setupCheckboxes();
    this.setupHiddenField();
  }

  /**
   * Setup the checkboxes to respond to clicks and update the hidden field
   */
  setupCheckboxes() {
    const $fieldset = $(".fieldset--report");
    const $checkboxes = $fieldset.find("input[type=checkbox]");
    const $hidden = $('input#checkboxes');

    $checkboxes.on("change", (ev) => {
      try {
        const { target } = ev;
        const $target = $(ev.target);

        if (target.checked) {
          $(".alert__no__select").hide();
        }

        if (target.checked) {
          if ($hidden && !$hidden.val()) {
            $hidden.val($target.attr('id'));
          } else if ($hidden && $hidden.val() && !($hidden.val().includes($target.attr('id')))) {
            $hidden.val($hidden.val() + ',' + $target.attr('id'));
          } else {
            throw new Error('No hidden field found');
          }
        } else if ($hidden && $hidden.val() && $hidden.val().includes($target.attr('id'))) {
          const id = $target.attr('id');
          const rx = new RegExp(id + ',?');
          $hidden.val($hidden.val().replace(rx, ''));
          if ($hidden.val().includes(',,')) $hidden.val($hidden.val().replace(',,', ','));
        } else {
          throw new Error('No hidden field found');
        }
      } catch (e) {
        logging.error(e);
      }
    });
  }

  /**
   * Setup the hidden field with the values of any pre-checked checkboxes
   */
  setupHiddenField() {
    try {
      const $fieldset = $(".fieldset--report");
      const $checkboxes = $fieldset.find("input[type=checkbox]");
      const $hidden = $('input#checkboxes');

      $checkboxes.each(function () {
        const $this = $(this)
        if ($this.is(":checked") || this.checked) {
          if ($hidden && !$hidden.val()) {
            $hidden.val($(this).attr('id'));
          } else if ($hidden && $hidden.val()) {
            $hidden.val($hidden.val() + ',' + $(this).attr('id'));
          } else {
            throw new Error('No hidden field found');
          }
        }
      });
    } catch (e) {
      logging.error(e);
    }
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
    const $form = $button.closest("form");
    const $fieldset = $(".fieldset--report");
    const checked = this.checkForAtLeastOneValue($fieldset);

    if (!this.canSubmitRecordForm) {
      ev.preventDefault();

      const isValid = validateRequiredFields($form);

      if (isValid && checked) {
        this.submit($form);
      } else if (!checked) {
        $(".alert__no__select").show();
      }
    }
  }

  /**
   * Submit the form
   * @param {jQuery<HTMLFormElement>} $form form to submit
   */
  submit($form) {
    $form.trigger("submit");
  }
}

export default CreateReportButtonComponent;
