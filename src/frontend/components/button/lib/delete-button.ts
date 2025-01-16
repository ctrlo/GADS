// noinspection ExceptionCaughtLocallyJS

import {logging} from "logging";

/**
 * Create delete button
 * @param element {JQuery<HTMLElement>} - Element to act as a delete button
 */
export default function createDeleteButton(element: JQuery<HTMLElement>) {
    element.on('click', (ev) => {
        const $button = $(ev.target).closest('button')
        const title = $button.attr('data-title')
        const id = $button.attr('data-id')
        const target = $button.attr('data-bs-target')
        const toggle = $button.attr('data-bs-toggle')
        const modalTitle = title ? `Delete - ${title}` : 'Delete'
        const $deleteModal = $(document).find(`.modal--delete${target}`)

        try {
            if (!id || !target || !toggle) {
                throw 'Delete button should have data attributes id, toggle and target!'
            } else if ($deleteModal.length === 0) {
                throw `There is no modal with id: ${target}`
            }
        } catch (e) {
            //@ts-expect-error - test is a global variable
            if(window.test)
                throw e;
            else
                logging.error(e)
            this.el.on('click', function (e: JQuery.ClickEvent) {
                e.stopPropagation()
            });
        }

        $deleteModal.find('.modal-title').text(modalTitle)
        $deleteModal.find('button[type=submit]').val(id)
    });
}
