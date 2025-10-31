/**
 * Create a button that removes the unload event listener
 * @param {JQuery<HTMLElement>} element The button element to add the click event to
 */
export default function createRemoveUnloadButton(element: JQuery<HTMLElement>) {
    element.on('click', () => {
        $(window).off('beforeunload');
    });
}
