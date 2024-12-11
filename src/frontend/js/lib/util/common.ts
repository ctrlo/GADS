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

export const fromJson = <T> (json: string | object): T | object => {
    try {
        if (!json || json === '') return {};
        if (typeof json === 'string') {
            const result = JSON.parse(json);
            return result as T ?? result;
        }
        return json as T ?? json;
    } catch {
        return {};
    }
}

export const compare = <T>(a: T, b: T): boolean => {
    for(const key in a) {
        if(typeof a[key] === 'object' && typeof b[key] === 'object') {
            if(!compare(a[key], b[key])) return false;
        }else if(a[key] !== b[key]) {
            return false;
        }
    }
    return true;
}