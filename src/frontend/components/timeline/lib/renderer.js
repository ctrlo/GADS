/**
 * Render a timeline item as an HTML element.
 * @param {*} args Unknown arguments, typically containing content to render
 * @returns {HTMLElement} The rendered HTML element containing the content
 */
export const itemRenderer = (args) => {
    const container = document.createElement('div');
    container.className = 'timeline-tippy';
    container.setAttribute('data-tippy-sticky', 'true');
    container.setAttribute('data-tippy-interactive', 'true');
    container.setAttribute('data-tippy-content', renderTippy(args));
    container.setAttribute('data-tippy-animation', 'scale');
    container.setAttribute('data-tippy-duration', '0');
    container.setAttribute('data-tippy-followCursor', 'initial');
    container.setAttribute('data-tippy-arrow', 'true');
    container.setAttribute('data-tippy-delay', '[200, 200]');
    container.innerText = args.content.split(';')[0] || 'No content provided';
    return container;
}

/**
 * Render the Tippy content for a timeline item.
 * @param {*} args Unknown arguments, typically containing current_id and values
 * @returns {string} The rendered HTML string for the Tippy content
 */
const renderTippy = (args) => {
    return `<div>
        <b>Record ${args.current_id}</b><br>
        <ul class="list-unstyled">
            ${args.values.map(value => `<li>${value.name}: ${value.value}</li>`).join('')}
        </ul>
        <a class="moreinfo" data-record-id="${args.current_id}">Read more</a> |
        <a href="/edit/${args.current_id}">Edit item</a>
    </div>`;
}