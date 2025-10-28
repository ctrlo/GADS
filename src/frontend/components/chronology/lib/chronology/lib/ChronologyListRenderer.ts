import { Renderable } from "util/renderable";
import { ChronologyRenderer } from "./ChronologyRenderer";
import { Chronology } from "./interfaces";

/**
 * ChronologyListRenderer is responsible for rendering a list of chronology entries.
 * It takes an array of Chronology objects and renders them into a single HTMLDivElement.
 * @implements { Renderable<HTMLDivElement> }
 */
export class ChronologyListRenderer implements Renderable<HTMLDivElement> {
    constructor(private chronologies: Chronology[]) { }

    render(): HTMLDivElement {
        const container = document.createElement("div");
        container.classList.add("chronology-list");

        this.chronologies.forEach(chronology => {
            const renderer = ChronologyRenderer.createRenderer(chronology);
            container.appendChild(renderer.render());
        });

        return container;
    }
}
