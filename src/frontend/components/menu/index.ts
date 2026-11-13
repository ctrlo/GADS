import { initializeComponent } from "component";
import MenuComponent from "./lib/component";

export default (scope: any) => initializeComponent(scope, ".dropdown__toggle", MenuComponent);
