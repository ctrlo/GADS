import { Renderable } from "util/renderable";
import { Chronology, ChronologyAction, ChronologyCreate, ChronologyUpdate } from "./interfaces";
import { ChronologyUpdateAction } from "./types";
import { RenderMoreLess } from "../../../../more-less/lib/MoreLessRenderer";

const MORE_LESS_THRESHOLD = 50;

/**
 * ChronologyRenderer is an abstract class that defines the structure for rendering chronology entries.
 * @implements {Renderable<HTMLDivElement>}
 * @abstract
 */
export abstract class ChronologyRenderer implements Renderable<HTMLDivElement> {
    static createRenderer(chronology: Chronology): Renderable<HTMLDivElement> {
        if (chronology.action.type === "update") {
            return new UpdateChronologyRenderer(chronology as ChronologyUpdate);
        } else if (chronology.action.type === "create") {
            return new CreateChronologyRenderer(chronology as ChronologyCreate);
        }
        throw new Error("Unknown chronology action type");
    }

    render(): HTMLDivElement {
        return this.createCard();
    }

    /**
     * Creates the title for the chronology card.
     * @returns {HTMLHeadingElement} The title element for the card.
     * @abstract
     * @protected
     */
    protected abstract createCardTitle(): HTMLHeadingElement;

    /**
     * Creates the content for the chronology card.
     * @returns {HTMLDivElement} The content element for the card.
     * @abstract
     * @protected
     */
    protected abstract createCardContent(): HTMLDivElement;

    /**
     * Creates a card element to display the chronology entry.
     * @returns {HTMLDivElement} The card element containing the title and content.
     * @protected
     */
    protected createCard(): HTMLDivElement {
        const card = document.createElement("div");
        card.classList.add("card", "card-secondary", "mb-3");
        const cardHeader = document.createElement("div");
        cardHeader.classList.add("card-header");
        cardHeader.appendChild(this.createCardTitle());
        card.appendChild(cardHeader);
        const cardBody = this.createCardContent();
        card.appendChild(cardBody);
        return card;
    }

    /**
     * Render a table element containing the object keys as headers, and the values as fields.
     * @param { Record<string, string|null> } data The data for which to create the table
     * @returns { HTMLTableElement } A table element containing the object keys as headers, and the values as fields
     */
    protected createTableContent(data: { [key: string]: string | null; }): HTMLTableElement {
        const table = document.createElement("table");
        table.classList.add("table", "table-bordered", "table-striped");
        const thead = document.createElement("thead");
        const tbody = document.createElement("tbody");

        const headerRow = document.createElement("tr");
        for (const key of Object.keys(data)) {
            const th = document.createElement("th");
            th.textContent = key;
            headerRow.appendChild(th);
        }
        thead.appendChild(headerRow);

        const dataRow = document.createElement("tr");
        for (const value of Object.values(data)) {
            const td = document.createElement("td");
            td.textContent = value !== null ? String(value) : "N/A";
            dataRow.appendChild(td);
        }
        tbody.appendChild(dataRow);

        table.appendChild(thead);
        table.appendChild(tbody);
        return table;
    }
}

/**
 * CreateChronologyRenderer is a concrete implementation of ChronologyRenderer for rendering create actions.
 * @extends {ChronologyRenderer}
 */
class CreateChronologyRenderer extends ChronologyRenderer {
    /**
     * Creates an instance of CreateChronologyRenderer.
     * @param chronology The chronology for which to create the renderer
     */
    constructor(private chronology: Chronology) {
        super();
    }

    /**
     * Create the title for the chronology card.
     * @returns {HTMLHeadingElement} The title element for the card, indicating the creation action
     * @protected
     * @override
     */
    createCardTitle(): HTMLHeadingElement {
        const title = document.createElement("h3");
        title.classList.add("card-title");
        title.textContent = `${this.chronology.action.datetime} - record created by ${this.chronology.action.user}`;
        return title;
    }

    /**
     * Create the content for the chronology card.
     * @returns {HTMLDivElement} The content element for the card, displaying the data of the created record
     * @protected
     * @override
     */
    createCardContent(): HTMLDivElement {
        const content = document.createElement("div");
        content.classList.add("card-body");
        const list = document.createElement("div");
        list.classList.add("list", "list--vertical", "list--key-value", "list--no-borders");
        const ul = document.createElement("ul");
        ul.classList.add("list__items");
        for (const [key, value] of Object.entries(this.chronology.data)) {
            const li = document.createElement("li");
            li.classList.add("list__item");
            const keySpan = document.createElement("span");
            keySpan.classList.add("list__key");
            keySpan.textContent = key;
            const valueSpan = document.createElement("span");
            valueSpan.classList.add("list__value");

            if (typeof value === "object" && value !== null) {
                valueSpan.appendChild(RenderMoreLess(this.createTableContent(value), key));
            } else {
                const v = String(value);
                if (v.length > MORE_LESS_THRESHOLD) {
                    const d = document.createElement("div");
                    d.textContent = v;
                    valueSpan.appendChild(RenderMoreLess(d, key));
                } else {
                    valueSpan.textContent = v;
                }
            }

            li.appendChild(keySpan);
            li.appendChild(valueSpan);
            ul.appendChild(li);
        }
        list.appendChild(ul);
        content.appendChild(list);
        return content;
    }
}

/**
 * UpdateChronologyRenderer is a concrete implementation of ChronologyRenderer for rendering update actions.
 * @extends {ChronologyRenderer}
 */
class UpdateChronologyRenderer extends ChronologyRenderer {
    /**
     * Creates an instance of UpdateChronologyRenderer.
     * @param chronology The chronology for which to create the renderer
     */
    constructor(private chronology: Chronology & { action: ChronologyAction & { type: "update" } } & { data: ChronologyUpdateAction }) {
        super();
    }

    /**
     * Create the title for the chronology card.
     * @returns {HTMLHeadingElement} The title element for the card, indicating the update action
     * @protected
     * @override
     */
    createCardTitle(): HTMLHeadingElement {
        const title = document.createElement("h3");
        title.classList.add("card__header");
        title.textContent = `${this.chronology.action.datetime} - record updated by ${this.chronology.action.user}`;
        return title;
    }

    /**
     * Create the content for the chronology card.
     * @returns {HTMLDivElement} The content element for the card, displaying the changes made to the record
     * @protected
     * @override
     */
    createCardContent(): HTMLDivElement {
        const content = document.createElement("div");
        content.classList.add("card-body");
        const list = document.createElement("div");
        list.classList.add("list", "list--vertical", "list--key-value", "list--no-borders");
        const ul = document.createElement("ul");
        ul.classList.add("list__items");
        for (const [key, value] of Object.entries(this.chronology.data)) {
            const li = document.createElement("li");
            li.classList.add("list__item");
            const keySpan = document.createElement("span");
            keySpan.classList.add("list__key");
            keySpan.textContent = key;
            const valueSpan = document.createElement("span");
            valueSpan.classList.add("list__value");

            const newContent = value.new;
            const oldContent = value.old;
            if (newContent && !oldContent) {
                valueSpan.textContent = `added with value ${newContent}`;
            } else if (oldContent && !newContent) {
                valueSpan.textContent = `removed`;
            } else {
                valueSpan.textContent = `changed to ${newContent}`;
            }

            li.appendChild(keySpan);
            li.appendChild(valueSpan);
            ul.appendChild(li);
        }
        list.appendChild(ul);
        content.appendChild(list);
        return content;
    }
}
