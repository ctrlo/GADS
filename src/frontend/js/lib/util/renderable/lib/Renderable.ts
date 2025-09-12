/**
 * Renderable interface for defining renderable components.
 * This interface requires a render method that returns an HTML element or a jQuery-wrapped element.
 * It also includes a renderAsync method that returns a Promise resolving to the same type.
 *
 * @template T - The type of the HTML element to be rendered, defaulting to HTMLElement.
 * @interface Renderable
 * @property {function(): T | JQuery<T>} render - Synchronous render method.
 * @property {function(): Promise<T | JQuery<T>>} renderAsync - Asynchronous render method returning a Promise.
 *
 * @example
 * class MyComponent implements Renderable<HTMLDivElement> {
 *     render(): HTMLDivElement {
 *         const div = document.createElement('div');
 *         div.textContent = 'Hello, World!';
 *         return div;
 *     }
 * }
 */
export interface Renderable<T extends HTMLElement = HTMLElement> {
    /**
     * Synchronous render method that returns an HTML element or a jQuery-wrapped element.
     * @returns {T} The rendered HTML element or jQuery-wrapped element.
     */
    render(): T;
}