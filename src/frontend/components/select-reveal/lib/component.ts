import { Component } from "component";

/**
 *
 */
export default class SelectRevealComponent extends Component {
    private $el: JQuery<HTMLElement>;
    private $target: JQuery<HTMLElement>;

    /**
     *
     */
    constructor(element:HTMLElement) {
        super(element);
        this.$el = $(element);
        this.init();
    }

    /**
     *
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
            const selectedValue = parseInt($(ev.currentTarget).val().toString());
            console.log(`Selected value: ${selectedValue}`);
            if (selectedValue === value) {
                this.$el.show();
            } else {
                this.$el.hide();
            }
        });
    }
}
