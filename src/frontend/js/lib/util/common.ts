export type EventOrJQueryEvent = Event | JQuery.Event;
export type TOrJQuery<T> = T | JQuery<T>;
export type ElementOrJQueryElement = TOrJQuery<HTMLElement>;

export const stopPropagation = (e: EventOrJQueryEvent) => {
    try {
        e.stopPropagation();
        e.preventDefault();
    } catch (e) {
        //ignore - this is because unit tests are failing - there will be a "better" fix incoming in the future
    }
}

export const hasClass = (element: ElementOrJQueryElement, className: string) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    return $el.hasClass(className);
};

export const hideElement = (element: ElementOrJQueryElement) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if(hasClass($el, 'hidden')) return;
    $el.addClass('hidden');
    $el.attr('aria-hidden', 'true');
    $el.css('display', 'none');
    $el.css('visibility', 'hidden');
};

export const showElement = (element: ElementOrJQueryElement) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if (!hasClass($el, 'hidden')) return;
    removeClass($el, 'hidden');
    $el.removeAttr('aria-hidden');
    $el.removeAttr('style');
};

export const addClass = (element: ElementOrJQueryElement, className: string) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if (hasClass($el, className)) return;
    $el.addClass(className);
}

export const removeClass = (element: ElementOrJQueryElement, className: string) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if (!hasClass($el, className)) return;
    $el.removeClass(className);
}

export const fromJson = (json: String | object) => {
    try {
        if (!json || json === '') return undefined;
        if (typeof json === 'string') {
            return JSON.parse(json);
        }
        return json;
    } catch (e) {
        return undefined;
    }
}
