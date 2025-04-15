/**
 * Hide an element by adding the 'hidden' class and setting aria-hidden to true.
 * @param element The element to hide
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
 * Show an element by removing the 'hidden' class and setting aria-hidden to false.
 * @param element The element to show
 */
export const showElement = (element: HTMLElement | JQuery<HTMLElement>) => {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if (!$el.hasClass('hidden')) return;
    $el.removeClass('hidden');
    $el.removeAttr('aria-hidden');
    $el.removeAttr('style');
};

/**
 * Convert a string or object to a JSON object.
 * @param json The JSON string or object to parse
 * @returns An object representation of the JSON string or the original object if it is already an object
 */
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
