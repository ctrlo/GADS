import { BaseButton } from "./base-button";

class ShowBlankButton extends BaseButton {
    type="btn-js-show-blank";
    click(ev: JQuery.ClickEvent): void {
        const $button = $(ev.target).closest('.btn-js-show-blank');
        const $buttonTitle = $button.find('.btn__title')[0];
        const showBlankFields = $buttonTitle.innerHTML === "Show blank values";

        $(".list__item--blank").toggle(showBlankFields);

        $buttonTitle.innerHTML = showBlankFields
            ? "Hide blank values"
            : "Show blank values";
    }
}

export default function createShowBlankButton(element: HTMLElement | JQuery<HTMLElement>) {
    return new ShowBlankButton($(element));
}