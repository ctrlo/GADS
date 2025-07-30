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
        if (!json || json === '') return {};
        if (typeof json === 'string') {
            return JSON.parse(json);
        }
        return json;
    } catch {
        return {};
    }
};

/**
 * Encode HTML entities in a string.
 * @param {string} input String to encode HTML entities
 * @returns {string} String with HTML entities encoded
 */
export const encodeHTMLEntities = (input: string): string => {
    return $('<textarea/>').text(input)
        .html();
};
