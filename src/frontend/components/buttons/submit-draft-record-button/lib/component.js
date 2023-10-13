import { Component } from "component";

class SubmitDraftRecordComponent extends Component {
  constructor(element) {
    super(element);
    this.el = $(this.element);
    this.initSubmitDraftRecord();
  }

  initSubmitDraftRecord() {
    this.el.on("click", (ev) => {
      this.submitDraftRecord(ev);
    });
  }

  submitDraftRecord(ev) {
    const $button = $(ev.target).closest("button");
    const $form = $button.closest("form");

    // Remove the required attribute from hidden required dependent fields
    $form.find(".form-group *[aria-required]").removeAttr("required");
  }
}

export default SubmitDraftRecordComponent;
