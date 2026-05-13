import { Renderable } from 'util/renderable';

/**
 * A simple button component that can be rendered to the DOM. It takes a text, an onClick handler, and an optional list of CSS classes.
 */
export class RenderableButton implements Renderable<HTMLButtonElement> {
    classList: string[] = [];

    /**
     * Creates a new RenderableButton instance.
     * @param text The text to display in the button
     * @param onClick The onclick listener for when the button is clicked
     * @param classList Any classes to add to the button
     */
    constructor(private readonly text: string, private readonly onClick: (ev: MouseEvent)=>void, ...classList: string[]) {
        this.classList = classList;
    }

    /**
     * Renders the button to an HTMLButtonElement.
     * @returns A button element to attach to the DOM
     */
    render(): HTMLButtonElement {
        const button = document.createElement('button');
        button.textContent = this.text;
        button.addEventListener('click', this.onClick);
        button.classList.add(...this.classList, 'btn');
        const btnType = this.classList.find(b=>b.startsWith('btn-')) ? '' : 'btn-default';
        if(btnType) {
            button.classList.add(btnType);
        }
        return button;
    }
}
