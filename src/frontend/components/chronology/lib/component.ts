import { Component, initializeRegisteredComponents } from "component";
import { ChronologyListRenderer } from "./chronology";
import { logging } from "logging";
import { ChronologyResult } from "./chronology/lib/interfaces";
import { ChronologyLoadPageEvent } from "./chronology/lib/events";

/**
 * ChronologyComponent is a component that fetches and displays a chronology by its ID.
 * @extends {Component}
 */
export default class ChronologyComponent extends Component {
    /**
     * @private
     * @type {JQuery<HTMLElement>}
     * jQuery object representing the component's root element.
     * This is used to manipulate the DOM and append rendered chronology entries.
     */
    private $el: JQuery<HTMLElement>;

    /**
     * ChronologyComponent constructor.
     * @param {HTMLElement} element The element to which this component is attached.
     */
    constructor(element: HTMLElement) {
        super(element);
        this.$el = $(element);
        this.init();
    }

    /**
     * Initializes the component by fetching the chronology data.
     * It retrieves the chronology ID from the element's data attribute and calls fetchChronology.
     * If the ID is not provided or invalid, it logs an error.
     * @private
     * @throws {Error} If the chronology ID is not provided or invalid.
     */
    private init(): void {
        const id_string = this.$el.data("chronology-id");
        const id = id_string ? parseInt(id_string, 10) : null;
        if (id) {
            this.fetchChronology(id);
        } else {
            logging.error("Chronology ID is not provided or invalid.");
        }
        this.$el.on('chronology:loadpage', (event: ChronologyLoadPageEvent) => {
            event.preventDefault();
            const page = event.page;
            if (page) {
                $("#chronology-loading").show();
                this.fetchChronology(id, page);
            } else {
                logging.error("No page number provided in the event.");
            }
        });
    }

    /**
     * Fetches the chronology data for a given ID and page number.
     * @param id The ID of the current record for which to fetch chronology
     * @param page The page number of the chronology for the record to fetch
     */
    private fetchChronology(id: number, page: number = 1): void {
        fetch(`/api/chronology/${id}?page=${page}`)
            .then(response => response.json())
            .then((data: ChronologyResult) => {
                const renderer = new ChronologyListRenderer(data.result);
                const component = renderer.render();
                this.$el.append(component);
                return { page: data.page, last_page: data.last_page };
            }).then(({ page, last_page }) => {
                $("#chronology-loading").hide();
                const $event = $.Event('chronology:pageupdated', {
                    page: page,
                    total: last_page,
                });
                this.$el.trigger($event);
            }).catch(error => {
                console.error(error);
                logging.error("Error fetching chronology:", error);
                this.$el.append("<p>Error loading chronology data.</p>");
            }).finally(()=>{
                initializeRegisteredComponents(document.body);
            });
    }
}
