import {ElementLike} from "../../../testing/globals.definitions";
// Instanceof is used throughout, this is because we need to ensure ElementLike is not overwritten by JQuery (else we could use `$el=$(element)`)

export const hideElement = (element: HTMLElement | ElementLike | JQuery<HTMLElement>) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if($el.hasClass('hidden')) return;
    $el.addClass('hidden');
    $el.attr('aria-hidden', 'true');
    $el.css('display', 'none');
    $el.css('visibility', 'hidden');
};

export const showElement = (element: HTMLElement | ElementLike |JQuery<HTMLElement>) => {
    const $el = element instanceof HTMLElement? $(element) : element;
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
