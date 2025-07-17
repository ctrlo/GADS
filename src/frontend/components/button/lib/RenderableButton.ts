import { Renderable } from 'util/renderable';

/**
 * A simple button component that can be rendered to the DOM.
 * It accepts text, an onClick handler, and optional CSS classes.
 */
export class RenderableButton implements Renderable<HTMLButtonElement> {
    classList: string[] = [];

    /**
     * Create a new RenderableButton.
     * @param text The button text
     * @param onClick The click event to fire when the button is clicked
     * @param classList Any classes to add to the button
     */
    constructor(private readonly text: string, private readonly onClick: (ev: MouseEvent)=>void, ...classList: string[]) {
        this.classList = classList;
    }

    /**
     * Render the button to the DOM.
     * @returns A button to add to the DOM
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
