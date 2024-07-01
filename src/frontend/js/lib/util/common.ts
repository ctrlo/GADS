/**
 * Stop propagation of an event and prevent the default action
 * @param e THe event to stop propagation for
 * @deprecated This function is no longer needed, I shall work on removing from the codebase as I go along
 */
export function stopPropagation(e: Event): void;
export function stopPropagation(e: JQuery.Event): void;
export function stopPropagation(e: Event | JQuery.Event): void {
    e.stopPropagation();
    e.preventDefault();
};

/**
 * This works as a helper function to check if an element has a class - it is a wrapper around jQuery's hasClass method for use with HTMLElements if needed
 * @param element The element to check for the class
 * @param className The classname to check for
 */
export function hasClass(element: HTMLElement, className: string): boolean;
export function hasClass(element: JQuery<HTMLElement>, className: string): boolean;
export function hasClass(element: HTMLElement | JQuery<HTMLElement>, className: string): boolean {
    const $el = element instanceof HTMLElement ? $(element) : element;
    return $el.hasClass(className);
};

/**
 * Hide an element - this also adds ARIA attributes to the element to ensure it is hidden from screen readers and other assistive technologies
 * @param element The element to hide
 */
export function hideElement(element: HTMLElement): void;
export function hideElement(element: JQuery<HTMLElement>): void;
export function hideElement(element: HTMLElement | JQuery<HTMLElement>): void {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if (hasClass($el, "hidden")) return;
    $el.addClass("hidden");
    $el.attr("aria-hidden", "true");
    $el.css("display", "none");
    $el.css("visibility", "hidden");
};

/**
 * Show an element - this also removes ARIA attributes to the element to ensure it is shown to screen readers and other assistive technologies
 * @param element The element to show
 */
export function showElement(element: HTMLElement): void;
export function showElement(element: JQuery<HTMLElement>): void;
export function showElement(element: HTMLElement | JQuery<HTMLElement>): void {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if (!hasClass($el, "hidden")) return;
    removeClass($el, "hidden");
    $el.removeAttr("aria-hidden");
    $el.removeAttr("style");
};

/**
 * Add a class to an element if it does not already have it - this is a wrapper around jQuery's addClass method for use with HTMLElements if needed
 * @param element The element to add the class to
 * @param className The class to add
 */
export function addClass(element: HTMLElement, className: string): void;
export function addClass(element: JQuery<HTMLElement>, className: string): void;
export function addClass(element: HTMLElement | JQuery<HTMLElement>, className: string): void {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if (hasClass($el, className)) return;
    $el.addClass(className);
};

/**
 * Remove a class from an element if it has it - this is a wrapper around jQuery's removeClass method for use with HTMLElements if needed
 * @param element The element to remove the class from
 * @param className The class to remove
 */
export function removeClass(element: HTMLElement, className: string): void;
export function removeClass(element: JQuery<HTMLElement>, className: string): void;
export function removeClass(element: HTMLElement | JQuery<HTMLElement>, className: string): void {
    const $el = element instanceof HTMLElement ? $(element) : element;
    if (!hasClass($el, className)) return;
    $el.removeClass(className);
};

/**
 * Create a TypeScript object from a JSON string or object
 * @param json The JSON string or object to convert to a TypeScript object
 */
export function fromJson<T>(json: string): T;
export function fromJson<T>(json: object): T;
export function fromJson<T>(json: string | object): T {
    try {
        if (!json || json === "") return {} as T;
        if (typeof json === "string") {
            return JSON.parse(json);
        }
        return json as T;
    } catch (e) {
        return {} as T;
    }
};
