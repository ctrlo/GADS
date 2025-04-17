import { initializeComponent } from "component";
import BootstrapPopoverComponent from "./lib/component";

export default (scope:any) =>{
    //@ts-expect-error Typings on initializeComponent are incorrect
    initializeComponent(scope, '[data-bs-toggle="popover"]', BootstrapPopoverComponent);
}
