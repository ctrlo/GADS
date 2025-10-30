export function RenderMoreLess<T extends HTMLElement = HTMLElement>(element: T, header: string = "Unknown") {
    const moreLessDiv = document.createElement('div');
    moreLessDiv.className = 'more-less';
    moreLessDiv.dataset.column = header;
    moreLessDiv.appendChild(element);

    import("./component").then(({ default: MoreLess }) => new MoreLess(moreLessDiv));

    return moreLessDiv;
}
