type EventOrJQueryEvent = Event | JQuery.Event;
type ElementOrJQueryElement = HTMLElement | JQuery<HTMLElement>;

export const stopPropagation = (e: EventOrJQueryEvent) => {
    e.stopPropagation();
    e.preventDefault();
}

const hasClass = (element: ElementOrJQueryElement, className: string) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    return $el.hasClass(className);
};

export const hideElement = (element: ElementOrJQueryElement) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if(hasClass($el, 'hidden')) return;
    $el.addClass('hidden');
    $el.attr('aria-hidden', 'true');
};

export const showElement = (element: ElementOrJQueryElement) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if(!hasClass($el, 'hidden')) return;
    $el.removeClass('hidden');
    $el.removeAttr('aria-hidden');
};
