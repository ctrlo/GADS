import { initializeComponent } from "component";
import BootstrapPopoverComponent from "./lib/component";

export default (scope:any) =>{
    initializeComponent(scope, "[data-bs-toggle=\"popover\"]", BootstrapPopoverComponent);
};
