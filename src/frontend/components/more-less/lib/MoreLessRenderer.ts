function RenderMoreLess(element: HTMLElement)
function RenderMoreLess(element: Text)
function RenderMoreLess(element: Text, header: string)
function RenderMoreLess<T extends HTMLElement = HTMLElement>(element: T, header: string)
function RenderMoreLess<T extends HTMLElement | Text = HTMLElement>(element: T, header: string = "Unknown") {
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
