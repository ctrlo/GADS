function RenderMoreLess(element: HTMLElement): HTMLDivElement;
function RenderMoreLess(element: Text): HTMLDivElement;
function RenderMoreLess(element: Text, header: string): HTMLDivElement;
function RenderMoreLess<T extends HTMLElement = HTMLElement>(element: T, header: string): HTMLDivElement;
/**
 * Render a "more-less" component with the provided element and optional header.
 * If the element is a Text node, it will be wrapped in a span.
 * If the element is an HTMLElement, it will be directly appended to the more-less div.
 *
 * @param {HTMLElement | Text} element - The element to render inside the more-less component.
 * @param {string} [header="Unknown"] - The header for the more-less component.
 * @returns {HTMLDivElement} The rendered more-less component.
 */
function RenderMoreLess<T extends HTMLElement | Text = HTMLElement>(element: T, header: string = 'Unknown'): HTMLDivElement {
    const moreLessDiv = document.createElement('div');
    moreLessDiv.className = 'more-less';
    moreLessDiv.dataset.column = header;
    if(element instanceof HTMLElement) {
        moreLessDiv.appendChild(element);
    } else if (element instanceof Text) {
        const span = document.createElement('span');
        span.appendChild(element);
        moreLessDiv.appendChild(span);
    }

    return moreLessDiv;
}

export { RenderMoreLess };
