import { Component } from "component";

/**
 * A component that reveals or hides an element based on the selected value of a target select element.
 */
export default class SelectRevealComponent extends Component {
    private $el: JQuery<HTMLElement>;
    private $target!: JQuery<HTMLElement>;

    /**
     * Initializes the component and sets up event listeners.
     */
    constructor(element:HTMLElement) {
        super(element);
        this.$el = $(element);
        this.init();
    }

    /**
     * Sets the initial visibility of the element based on the target's value and attaches the change event listener.
     */
    private init():void {
        const target = this.$el.data("select-target");
        const value = parseInt(this.$el.data("select-value"));
        this.$target = $(`#${target}`);
        if(!this.$target || !this.$target.length) throw new Error(`Target element with id "${target}" not found`);
        if(this.$target.val() === value) {
            this.$el.show();
        } else {
            this.$el.hide();
        }
        this.$target.on("change", (ev) => {
            const selectedValue = parseInt($(ev.currentTarget).val()!.toString());
            console.log(`Selected value: ${selectedValue}`);
            if (selectedValue === value) {
                this.$el.show();
            } else {
                this.$el.hide();
            }
        });
    }
}
