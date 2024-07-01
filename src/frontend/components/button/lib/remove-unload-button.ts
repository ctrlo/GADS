/**
 * Create a button that removes the unload event listener
 * @param element {JQuery<HTMLElement>} - The button element to add the click event to
 */
export default function createRemoveUnloadButton(element: JQuery<HTMLElement>) {
    element.on("click", () => {
        $(window).off("beforeunload");
    });
}
