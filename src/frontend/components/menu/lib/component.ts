import {Component} from "component";

export default class MenuComponent extends Component {
    constructor(element:HTMLElement) {
        super(element);
        this.initMenu();
    }

    private initMenu() {
        const $submenu = $(this.element).parent().find(".submenu");
        if (!$submenu || !$submenu.length) throw new Error("No submenu");
        $submenu.on("click", (ev) => ev.stopPropagation());
    }
}
