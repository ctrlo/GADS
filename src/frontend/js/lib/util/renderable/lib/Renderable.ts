/**
 * Renderable interface for defining renderable components.
 * This interface requires a render method that returns an HTML element or a jQuery-wrapped element.
 * It also includes a renderAsync method that returns a Promise resolving to the same type.
 */
export interface Renderable<T extends HTMLElement = HTMLElement> {
    /**
     * Synchronous render method that returns an HTML element or a jQuery-wrapped element.
     * @returns {T} The rendered HTML element or jQuery-wrapped element.
     */
    render(): T;
}
