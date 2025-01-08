export const hideElement = (element: HTMLElement | JQuery<HTMLElement>) => {
    const $el = $(element);
    if($el.hasClass('hidden')) return;
    $el.addClass('hidden');
    $el.attr('aria-hidden', 'true');
    $el.css('display', 'none');
    $el.css('visibility', 'hidden');
};

export const showElement = (element: HTMLElement |JQuery<HTMLElement>) => {
    const $el = $(element);
    if (!$el.hasClass('hidden')) return;
    $el.removeClass('hidden');
    $el.removeAttr('aria-hidden');
    $el.removeAttr('style');
};

export const fromJson = (json: String | object) => {
    try {
        if (!json || json === '') return {};
        if (typeof json === 'string') {
            return JSON.parse(json);
        }
        return json;
    } catch (e) {
        return {};
    }
}
