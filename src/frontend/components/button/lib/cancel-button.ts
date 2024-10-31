export default function createCancelButton(el: HTMLElement|JQuery<HTMLElement>) {
    const $el = $(el);
    if($el[0].tagName !== 'BUTTON') return;
    $el.data('cancel-button', "true");

    $el.on('click', () => {
        const href = $el.data('href');
        const ls = window.localStorage;
        const layout = $("body").data("layout-identifier");
        ls.getItem(`linkspace-record-change-${layout}`) && ls.removeItem(`linkspace-record-change-${layout}`);
        $(".linkspace-field").each((_,el) =>{
            const field_id = $(el).data("column-id");
            console.log("Field ID:",field_id);
            ls.getItem(`linkspace-column-${field_id}`) && ls.removeItem(`linkspace-column-${field_id}`);
        })
        if (href)
            window.location.href = href;
        else
            window.history.back();
    });
}