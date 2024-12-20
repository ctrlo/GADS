/**
 * Create a button that toggles the visibility of blank fields.
 * @param element {JQuery<HTMLElement>} The element to attach the button to.
 */
const createShowBlankButton = (element: JQuery<HTMLElement>) => {
  element.on('click', (ev) => {
    const $button = $(ev.target).closest('.btn-js-show-blank');
    const $buttonTitle = $button.find('.btn__title')[0];
    const showBlankFields = $buttonTitle.innerHTML === "Show blank values";

    $(".list__item--blank").toggle(showBlankFields);

    $buttonTitle.innerHTML = showBlankFields
      ? "Hide blank values"
      : "Show blank values";
  });
}

export default createShowBlankButton;