import { initializeRegisteredComponents } from "component";
import { logging } from "logging";
import ErrorHandler from "util/errorHandler";

export class LoadMoreChronologyButton {
    private page: number = 1;
    private $target: JQuery<HTMLElement>;
    private $spinner: JQuery<HTMLElement>;
    private errorHandler: ErrorHandler;

    constructor(private $el: JQuery<HTMLElement>) {
        logging.log("Initializing LoadMoreChronologyButton for element:", $el);
        // Where to put the chronology entries
        this.$target = $('.chronology');
        // Loading spinner
        this.$spinner = $(".chronology_spinner");
        // Error handler - attached to the chronology container
        this.errorHandler = new ErrorHandler(this.$target[0]);
        // Initialize the button
        this.init();
    }

    init() {
        // Set up the click event handler for the button
        this.$el.on("click", async () => {
            // When the button is clicked, fetch the next page of chronology data
            await this.fetchChronology();
        });
        // Fetch the first page of chronology data on initialization
        this.fetchChronology();
    }

    async fetchChronology() {
        // Disable the button
        this.$el.prop("disabled", true);
        // Get the record ID from the button's data attribute
        const recordId = this.$el.data("record-id");
        // Get the current page number
        const page = this.page;
        // Download the chronology data for the next page
        const url = `/api/chronology/${recordId}?page=${page}`;
        try {
            // Show the spinner while loading
            this.$spinner.show();
            // Fetch the data
            const response = await fetch(url);
            // Check if the response is successful
            if (!response.ok) {
                // display an error message using the error handler
                if(response.status !== 400) {
                    this.errorHandler.addError(`Failed to load chronology data. Server responded with status: ${response.status}`);
                }
                return;
            }
            // If successful, get the response data as text
            const html = await response.text();
            // Append the new data to the chronology list
            this.$target.append(html);
            // Initialize any new components in the newly loaded data (e.g., tooltips, popovers)
            initializeRegisteredComponents(this.$target[0]);
            // Increment the page number for the next fetch
            this.page += 1;
        } catch (error) {
            // If there is an error, use the error handler to display an error message
            this.errorHandler.addError(`An error occurred while loading chronology data. Please try again. Error: ${error}`);
        } finally {
            // Hide the spinner
            this.$spinner.hide();
            // Re-enable the button
            this.$el.prop("disabled", false);
        }
    }
}

const createLoadMoreChronologyButton = (el: JQuery<HTMLElement>) => {
    return new LoadMoreChronologyButton(el);
};

export default createLoadMoreChronologyButton;
