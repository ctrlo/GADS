import gadsStorage from "util/gadsStorage";

export function clearSavedFormValues($form: JQuery<HTMLElement>) {
    if(!$form || $form.length === 0) return;
    const layout = $("body").data("layout-identifier");
    gadsStorage.getItem(`linkspace-record-change-${layout}`)
        .then((item) => { if (item) gadsStorage.removeItem(`linkspace-record-change-${layout}`); })
        .then(() => Promise.all($form.find(".linkspace-field").map((_, el) => {
            const field_id = $(el).data("column-id");
            console.log("Field ID:", field_id);
            gadsStorage.getItem(`linkspace-column-${field_id}`)
                .then((item) => { if (item) gadsStorage.removeItem(`linkspace-column-${field_id}`); });
        })));
}
