import { Component } from "component";

// This is a basic wrapper around the Bootstrap popover component.
// We will (as time goes on) replace our own popover component with this to reduce the amount of code we have to maintain.
export default class BootstrapPopoverComponent extends Component {
    constructor(element:HTMLElement) {
        super(element);
        $(element).popover({html: true});
    }
}