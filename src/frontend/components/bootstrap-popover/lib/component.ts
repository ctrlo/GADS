import { Popover } from "bootstrap";
import { Component } from "component";

// This is a basic wrapper around the Bootstrap popover component.
// We will (as time goes on) replace our own popover component with this to reduce the amount of code we have to maintain.
export default class BootstrapPopoverComponent extends Component {
    constructor(element:HTMLElement) {
        super(element);
        const $el = $(element);
        const $contentElement = $el.closest(".popover-container")?.find(".popover-content");
        $contentElement?.hide();
        const content = $contentElement?.html() || $el.data("content") || $el.data("bs-content") || "empty";
        new Popover(element, {
            html: true,
            content: content,
        });
    }
}