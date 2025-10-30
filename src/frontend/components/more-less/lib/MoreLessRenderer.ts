import { initializeComponent } from "component";

export function RenderMoreLess<T extends HTMLElement = HTMLElement>(element: T, header: string = "Unknown") {
    const moreLessDiv = document.createElement('div');
    moreLessDiv.className = 'more-less';
    moreLessDiv.dataset.column = header;
    moreLessDiv.appendChild(element);

    // @ts-expect-error The component class has some odd TypeScript definitions
    import("./component").then(({ default: MoreLess }) => initializeComponent(moreLessDiv, '.more-less', MoreLess));

    return moreLessDiv;
}
