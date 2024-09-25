// Instanceof is used throughout, this is because we need to ensure ElementLike is not overwritten by JQuery (else we could use `$el=$(element)`)

export const hideElement = (element: HTMLElement | JQuery<HTMLElement>) => {
    const $el = $(element);
    if ($el.hasClass('hidden')) return;
    $el.addClass('hidden');
    $el.attr('aria-hidden', 'true');
    $el.css('display', 'none');
    $el.css('visibility', 'hidden');
};

export const showElement = (element: HTMLElement | JQuery<HTMLElement>) => {
    const $el = $(element);
    if (!$el.hasClass('hidden')) return;
    $el.removeClass('hidden');
    $el.removeAttr('aria-hidden');
    $el.removeAttr('style');
};

export const fromJson = <T = unknown>(json?: String | T | object): T => {
    let result: T;
    if (!json || json === '') throw new Error('Empty JSON');
    if (typeof json === 'string') {
        try {
            result = JSON.parse(json) as T
        } catch (e) {
            throw new Error('Invalid JSON');
        }
        if (!result) throw new Error('Invalid JSON');
        return result;
    }
    result = json as T;
    if (!result) throw new Error('Invalid JSON');
    return result;
}
