/**
 * Create remove curval button
 * @param element - The element to function as a remove curval button
 */
export default function createRemoveCurvalButton(element: JQuery<HTMLElement>) {
    element.on('click', (ev: JQuery.ClickEvent) => {
        const $btn = $(ev.target);

        if ($btn.closest('.table-curval-group').length) {
            if (confirm("Are you sure want to permanently remove this item?")) {
                const curvalItem = $btn.closest(".table-curval-item");
                const parent = curvalItem.parent();
                curvalItem.remove();
                if (parent && parent.children().length === 1) {
                    parent.children('.odd').children('.dataTables_empty').show();
                }
            } else {
                ev.preventDefault();
            }
        } else if ($btn.closest('.select-widget').length) {
            const fieldId = $btn.closest(".answer").find("input").prop("id");
            const $current = $btn.closest(".select-widget").find(".current");

            $current.find(`li[data-list-item=${fieldId}]`).remove();
            $btn.closest(".answer").remove();

            const $visible = $current.children("[data-list-item]:not([hidden])");
            $current.toggleClass("empty", $visible.length === 0);
        }
    });
}
