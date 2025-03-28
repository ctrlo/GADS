/**
 * Create a more info button that will load the record body into a modal.
 * @param element The button element to attach the event to.
 */
export default function createMoreInfoButton(element: HTMLElement | JQuery<HTMLElement>) {
    $(element).on("click", (ev) => {
        const $button = $(ev.target).closest('.btn');
        const record_id = $button.data('record-id');
        const modal_id = $button.data('target');
        const $modal = $(document).find(modal_id);

        $modal.find(".modal-title").text(`Record ID: ${record_id}`);
        $modal.find(".modal-body").text("Loading...");
        $modal.find(".modal-body").load("/record_body/" + record_id);

        /* Trigger focus restoration on modal close */
        $modal.one("show.bs.modal", (ev) => {
            /* Only register focus restorer if modal will actually get shown */
            if (ev.isDefaultPrevented()) return;
            $modal.one("hidden.bs.modal", () => {
                $button.is(":visible") && $button.trigger("focus");
            });
        });

        /* Stop propagation of the escape key, as may have side effects, like closing select widgets. */
        $modal.one("keyup", (ev) => {
            if (ev.key === "Escape") ev.stopPropagation();
        });
    });
}
