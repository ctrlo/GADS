import { Component } from "component";

class CheckboxComponent extends Component {
  constructor(element)  {
    super(element);
    this.el = $(this.element);

    this.initCheckbox();
  }

  // Intializes the checkbox
  initCheckbox() {
    const inputEl = $(this.el).find("input");
    const id = $(inputEl).attr("id");
    const $revealEl = $(`#${id}-reveal`);

    if ($(inputEl).is(":checked")) {
      this.showRevealElement($revealEl, true);
    }

    $(inputEl).on("change", () => {
      if ($(inputEl).is(":checked")) {
        this.showRevealElement($revealEl, true);
      } else {
        this.showRevealElement($revealEl, false);
      }
    });
  }

  showRevealElement($revealEl, bShow) {
    const strCheckboxRevealShowClassName = "checkbox-reveal--show";

    if (bShow) {
      $revealEl.addClass(strCheckboxRevealShowClassName);
    } else {
      $revealEl.removeClass(strCheckboxRevealShowClassName);
    }
  }
}

export default CheckboxComponent;
