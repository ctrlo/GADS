import { isString, isNumber, isArray, hasMethod, isObject } from './typechecks';

/**
 * Hides an element by adding the 'hidden' class and aria-hidden attribute.,
 * @param { HTMLElement | JQuery<HTMLElement> } element HTMLElement or jQuery element to hide
 */
export const hideElement = (element: HTMLElement | JQuery<HTMLElement>) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if ($el.hasClass('hidden')) return;
    $el.addClass('hidden');
    $el.attr('aria-hidden', 'true');
    $el.css('display', 'none');
    $el.css('visibility', 'hidden');
};

/**
 * Show an element by removing the 'hidden' class and aria-hidden attribute.
 * @param {HTMLElement | JQuery<HTMLElement>} element HTMLElement or jQuery element to show
 */
export const showElement = (element: HTMLElement | JQuery<HTMLElement>) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if (!$el.hasClass('hidden')) return;
    $el.removeClass('hidden');
    $el.removeAttr('aria-hidden');
    $el.removeAttr('style');
};

/**
 * Parse a JSON string or object and return an object.
 * @param {string | object} json JSON string or object to parse
 * @returns {object} Parsed object or an empty object if parsing fails
 */
export const fromJson = (json: string | object) => {
    try {
        // An empty string returns false in a boolean context, this also covers null and undefined
        if (!json || json === '') return {};
        if (typeof json === 'string') {
            return JSON.parse(json);
        }
        return json;
    } catch {
        return {};
    }
};



export const stringifyValue = (value: unknown): string => {
    if (isString(value)) {
        return value;
    } else if (isNumber(value)) {
        return value.toString();
    } else if (isArray(value)) {
        return value.map(stringifyValue).join(', ');
    } else if (hasMethod(value, 'toString') && value.toString !== Object.prototype.toString) { // Need to make sure toString is not the default one
        return value.toString();
    } else if (isObject(value)) {
        return JSON.stringify(value);
    }
    return String(value);
};
