import gadsStorage from "util/gadsStorage";

export default function createCancelButton(el: HTMLElement | JQuery<HTMLElement>) {
    const $el = $(el);
    if ($el[0].tagName !== 'BUTTON') return;
    $el.data('cancel-button', "true");

    $el.on('click', async () => {
        const href = $el.data('href');
        const layout = $("body").data("layout-identifier");
        await gadsStorage.getItem(`linkspace-record-change-${layout}`) && gadsStorage.removeItem(`linkspace-record-change-${layout}`);
        await Promise.all($(".linkspace-field").map(async (_, el) => {
            const field_id = $(el).data("column-id");
            console.log("Field ID:", field_id);
            await gadsStorage.getItem(`linkspace-column-${field_id}`) && gadsStorage.removeItem(`linkspace-column-${field_id}`);
        }));
        if (href)
            window.location.href = href;
        else
            window.history.back();
    });
}