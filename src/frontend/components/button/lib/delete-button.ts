// noinspection ExceptionCaughtLocallyJS

import {logging} from "logging";
import { BaseButton } from "./base-button";


class DeleteButton extends BaseButton {
    type = "btn-js-delete";
    
    click(ev: JQuery.ClickEvent): void {
        const $button = $(ev.target).closest('button');
        const title = $button.attr('data-title');
        const id = $button.attr('data-id');
        const target = $button.attr('data-target');
        const toggle = $button.attr('data-toggle');
        const modalTitle = title ? `Delete - ${title}` : 'Delete';
        const $deleteModal = $(document).find(`.modal--delete${target}`);

        try {
            if (!id || !target || !toggle) {
                throw 'Delete button should have data attributes id, toggle and target!';
            } else if ($deleteModal.length === 0) {
                throw `There is no modal with id: ${target}`;
            }
        } catch (e) {
            logging.error(e);
            this.element.on('click', function (e: JQuery.ClickEvent) {
                e.stopPropagation();
            });
        }

        $deleteModal.find('.modal-title').text(modalTitle);
        $deleteModal.find('button[type=submit]').val(id);
    }
}

export default function createDeleteButton(element: HTMLElement | JQuery<HTMLElement>) {
    return new DeleteButton($(element));
}
