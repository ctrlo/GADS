/**
 * Hidable class for managing visibility of HTML elements.
 * This class provides methods to hide an element by setting its display and visibility styles,
 * and updating its ARIA attributes.
 *
 * @template T - The type of the HTML element, defaulting to HTMLElement.
 * @abstract
 * @class Hidable
 */
export abstract class Hidable<T extends HTMLElement= HTMLElement> {
    protected element: T | null = null;

    /**
     * Sets the component to be hidden.
     */
    hide(): void {
        if(!this.element) return;
        this.element.style.display = 'none';
        this.element.style.visibility = 'hidden';
        this.element.ariaHidden = 'true';
    }
}