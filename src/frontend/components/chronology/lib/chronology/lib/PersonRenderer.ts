import { Renderable } from "util/renderable";
import { Person } from "./interfaces";

export class PersonRenderer implements Renderable<HTMLDivElement> {
    static counter =0;

    constructor(private readonly person: Person) {
    }

    render(): HTMLDivElement {
        let popover_body_string = '';
        if (this.person.id) {
            PersonRenderer.counter++;
            for (const detail of this.person.details) {
                if (popover_body_string) {
                    popover_body_string += `<br />`;
                }
                const insert_value = detail.value;
                if (detail.type == 'email') {
                    popover_body_string += `Email: <a href="mailto:${insert_value}">${insert_value}</a>`;
                } else {
                    const insert_label = detail.definition;
                    popover_body_string += `${insert_label}: ${insert_value}`;
                }
            }
        }

        const result = document.createElement('div');
        result.classList.add('popover-container', 'popover-container--text');
        const content = document.createElement('div');
        content.classList.add('popover-content');
        content.id = `popover-content-${PersonRenderer.counter}`;
        content.innerHTML = popover_body_string;
        result.appendChild(content);

        const button = document.createElement('button');
        button.classList.add('btn', 'btn-popover', 'btn-sm', 'btn-inverted', 'btn-info');
        button.type = 'button';
        button.title = this.person.text;
        button.setAttribute("aria-describedby", `popover-content-${PersonRenderer.counter}`);
        button.setAttribute("data-toggle", "popover");

        const span = document.createElement('span');
        span.innerText = this.person.text;
        button.appendChild(span);

        result.appendChild(button);

        return result;
    }
}
