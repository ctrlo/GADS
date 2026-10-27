import {Modal} from "bootstrap";
import CurvalModalComponent from "components/modal/modals/curval";

/**
 * Create modal curval button
 * @param {JQuery<HTMLElement>} element The element to function as an open modal curval button
 */
export default function createModalCurvalButton(element: JQuery<HTMLElement>) {
    /* The ID of the curval field that this button is for */
    const field_id = element.closest(".linkspace-field").data("column-id");
    /* To enable multiple modals to be open create a new modal for each curval
     * field, based on the field ID */
    const modal_id = "curvalModal" + field_id;
    /* Has it already been created in the document? */
    if (!$("#"+modal_id).length) {
        const $modal = $("#curvalModal").clone();
        $modal.attr("id", modal_id);
        /* This class is to ensure the component is initialized */
        $modal.addClass("modal--curval");
        /* Always add to the end, so that layering is possible and the last
         * always displays at the top */
        $modal.insertAfter($(".modal").last());
        CurvalModalComponent($modal.closest(".content-block"));
    }
    /* At this point the modal may have been initialised already (e.g.
     * if this code is to create the edit button for a curval) or it may
     * not, so use getOrCreateInstance() so that it handles both situations */
    const modal = Modal.getOrCreateInstance("#"+modal_id, {});
    element.on("click", () => modal.show(element.get(0)));
}
