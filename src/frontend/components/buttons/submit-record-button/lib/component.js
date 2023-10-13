import { Component } from "component";
import { validateRequiredFields } from "validation";
import RemoveUnloadButtonComponent from "../../remove-unload-button/lib/component";

class SubmitRecordButtonComponent extends Component {
  constructor(element) {
    super(element);
    this.el = $(this.element);
    this.requiredHiddenRecordDependentFieldsCleared = false;
    this.canSubmitRecordForm = false;
    this.initSubmitRecord();
  }

  initSubmitRecord() {
    if (this.el.hasClass("btn-js-remove-unload")) {
      new RemoveUnloadButtonComponent(this.element);
    }
    this.el.on("click", (ev) => {
      this.submitRecord(ev);
    });
  }

  submitRecord(ev) {
    const $button = $(ev.target).closest("button");
    const $form = $button.closest("form");
    const $requiredHiddenRecordDependentFields = $form.find(
      ".form-group[data-has-dependency='1'][style*='display: none'] *[aria-required]"
    );

    if (!this.requiredHiddenRecordDependentFieldsCleared) {
      ev.preventDefault();

      // Remove the required attribute from hidden required dependent fields
      $requiredHiddenRecordDependentFields.removeAttr("required");
      this.requiredHiddenRecordDependentFieldsCleared = true;
    }

    if (!this.canSubmitRecordForm) {
      ev.preventDefault();

      const isValid = validateRequiredFields($form);

      if (isValid) {
        this.canSubmitRecordForm = true;
        $button.trigger("click");
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
        $requiredHiddenRecordDependentFields.attr("required", "");
        this.requiredHiddenRecordDependentFieldsCleared = false;
      }
    }
  }
}

export default SubmitRecordButtonComponent;
