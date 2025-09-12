import { Renderable } from "util/renderable";

export class RenderableButton implements Renderable<HTMLButtonElement> {
    classList: string[] = [];

    constructor(private readonly text: string, private readonly onClick: (ev: MouseEvent)=>void, ...classList: string[]) {
        this.classList = classList;
    }

    render(): HTMLButtonElement {
        const button = document.createElement('button');
        button.textContent = this.text;
        button.addEventListener('click', this.onClick);
        button.classList.add(...this.classList, 'btn');
        const btnType = this.classList.find(b=>b.startsWith('btn-')) ? '' : 'btn-default'
        if(btnType) {
            button.classList.add(btnType);
        }
        return button;
    }
}
