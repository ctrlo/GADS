/**
 * Creates a DOM element of the specified type and applies the given properties.
 * @param {'button'|'div'|'input'} type The type of element to create.
 * @param {object} definition An object containing properties to set on the element.
 * @returns {JQuery<HTMLButtonElement | HTMLDivElement | HTMLInputElement>} A jQuery object containing the created element.
 */
function createElement(type: 'button', definition: object): JQuery<HTMLButtonElement>;
function createElement(type: 'div', definition: object): JQuery<HTMLDivElement>;
function createElement(type: 'input', definition: object): JQuery<HTMLInputElement>;
function createElement(type: 'button' | 'div' | 'input', definition: object): JQuery<HTMLButtonElement | HTMLDivElement | HTMLInputElement> {
    const el = document.createElement(type);
    for (const c in definition) {
        if (Array.isArray(definition[c]) && el[c].add) {
            el[c].add(...definition[c]);
        } else {
            el[c] = definition[c];
        }
    }
    return $(el);
}

export { createElement };
