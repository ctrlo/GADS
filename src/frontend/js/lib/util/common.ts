export type EventOrJQueryEvent = Event | JQuery.Event;
export type HtmlOrJQuery = HTMLElement | JQuery<HTMLElement>;

export const stopPropagation = (e: EventOrJQueryEvent) => {
    if (!e) return;
    try {
        e.stopPropagation();
    } catch (e) {
        //ignore 
    }
    try {
        e.preventDefault();
    } catch (e) {
        //ignore
    }
}

const hasClass = (element: HtmlOrJQuery, className: string) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    return $el.hasClass(className);
};

export const hideElement = (element: HtmlOrJQuery) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if (hasClass($el, 'hidden')) return;
    addClass($el, 'hidden');
    $el.attr('aria-hidden', 'true');
    $el.css('display', 'none');
    $el.css('visibility', 'hidden');
};

export const showElement = (element: HtmlOrJQuery) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if (!hasClass($el, 'hidden')) return;
    removeClass($el, 'hidden');
    $el.removeAttr('aria-hidden');
    $el.removeAttr('style');
};

export const addClass = (element: HtmlOrJQuery, className: string) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if (hasClass($el, className)) return;
    $el.addClass(className);
}

export const removeClass = (element: HtmlOrJQuery, className: string) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if (!hasClass($el, className)) return;
    $el.removeClass(className);
}
