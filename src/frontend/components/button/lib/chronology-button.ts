import { Component } from "component";

interface PageUpdate extends JQuery.TriggeredEvent {
    page: number;
    total: number;
}

/**
 * Button to load the next page of the chronology.
 */
export default class ChronologyButton extends Component {
    private $el: JQuery<HTMLElement>;
    private $target: JQuery<HTMLElement>;
    private $currentPage = 0;
    private $totalPages = 0;

    /**
     * Create a new ChronologyButton component.
     */
    constructor(element: HTMLElement) {
        super(element);
        this.$el = $(element);
        this.$target = $('.chronology');
        this.init();
    }

    /**
     * Initialise the button control
     */
    public init(): void {
        this.$target.on('chronology:pageupdated', (event: PageUpdate) => {
            this.$currentPage = event.page;
            this.$totalPages = event.total;
            this.updateButtonState();
        });
        this.$el.on('click', (event: JQuery.ClickEvent) => {
            this.$el.hide();
            event.preventDefault();
            const $event = $.Event('chronology:loadpage', {
                page: this.$currentPage + 1,
            })
            this.$target.trigger($event);
        });
    }

    /**
     * Update the button state based on the current page and total pages.
     */
    private updateButtonState(): void {
        if (this.$currentPage >= this.$totalPages) {
            const $el = this.$el;
            $el.show();
            $el.attr('disabled', 'disabled');
            $el.attr('aria-disabled', 'true');
            $el.addClass('disabled');
        }
    }
}
