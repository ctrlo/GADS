import { Component } from "component";

class ShowBlankButtonComponent extends Component {
  constructor(element) {
    super(element);
    this.el = $(this.element);
    this.initShowBlank();
  }

  initShowBlank() {
    this.el.on("click", (ev) => {
      const $button = $(ev.target).closest(".btn-js-show-blank");
      const $buttonTitle = $button.find(".btn__title")[0];
      const showBlankFields = $buttonTitle.innerHTML === "Show blank values";

      $(".list__item--blank").toggle(showBlankFields);

      $buttonTitle.innerHTML = showBlankFields
        ? "Hide blank values"
        : "Show blank values";
    });
  }
}

export default ShowBlankButtonComponent;
