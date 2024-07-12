import { initializeComponent } from "component";
import HelpView from "./lib/component";

export default (scope) =>{
    initializeComponent(scope, ".help-view", HelpView);
};