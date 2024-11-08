import { BaseButton } from "./base-button";

class RemoveUnloadButton extends BaseButton {
    type = "btn-js-remove-unload";
    
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    click(ev: JQuery.ClickEvent): void {
        $(window).off('beforeunload');
    }

}

export default function createRemoveUnloadButton(element: JQuery<HTMLElement>) {
    return new RemoveUnloadButton($(element));
}
