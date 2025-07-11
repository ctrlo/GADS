// TS errors if this is not here
declare global {
    interface Window {
        jQuery: JQueryStatic;
        $: JQueryStatic;
    }
}

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
        // An empty string returns false in a boolean context, this also covers null and undefined
        if (!json) return {};
        if (typeof json === 'string') {
            return JSON.parse(json);
        }
        return json;
    } catch (e) {
        return {}
    }
}

/**
 * Ensure jQuery is loaded and available globally.
 * This function checks if jQuery is already loaded, and if not, it loads it.
 */
export const initJquery = () => {
    if (window.jQuery && window.$) {
        console.log('jQuery already loaded');
    } else {
        (($) => {
            if (!window.jQuery) window.jQuery = $;
            if (!window.$) window.$ = $;
        })(jQuery);
    }
};
