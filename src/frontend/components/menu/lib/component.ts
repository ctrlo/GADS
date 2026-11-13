import {Component} from "component";

/**
 * Component to allow for submenus in the dropdown menus
 */
export default class MenuComponent extends Component {
    /**
     * Create a menu component
     * @param element The top-level menu element
     */
    constructor(element:HTMLElement) {
        super(element);
        this.initMenu();
    }

    /**
     * Initialize the submenu and stop propagation on click to stop hiding the menu
     */
    private initMenu() {
        const $submenu = $(this.element).parent().find(".submenu");
        if (!$submenu || !$submenu.length) throw new Error("No submenu");
        $submenu.on("click", (ev) => ev.stopPropagation());
    }
}
