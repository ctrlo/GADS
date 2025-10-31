import { Renderable } from 'js/lib/util/renderable';
import { Chronology } from './interfaces';
import { ChronologyRenderer } from './ChronologyRenderer';

/**
 * ChronologyListRenderer is responsible for rendering a list of chronology entries.
 * It takes an array of Chronology objects and renders them into a single HTMLDivElement.
 * @implements { Renderable<HTMLDivElement> }
 */
export class ChronologyListRenderer implements Renderable<HTMLDivElement> {
    /**
     * Create a new instance of ChronologyListRenderer.
     * @param {Chronology[]} chronologies - An array of Chronology objects to render.
     * @constructor
     * @throws {Error} If the provided chronologies are not an array or are empty.
     */
    constructor(private chronologies: Chronology[]) { }

    /**
     * Renders the list of chronologies into an HTMLDivElement.
     */
    render(): HTMLDivElement {
        const container = document.createElement('div');
        container.classList.add('chronology-list');

        this.chronologies.forEach(chronology => {
            const renderer = ChronologyRenderer.createRenderer(chronology);
            container.appendChild(renderer.render());
        });

        return container;
    }
}
