import { initializeComponent } from "component";
import CalcFieldsComponent from "./lib/component";

export default (scope) => initializeComponent(scope, "[data-calc-depends-on]", CalcFieldsComponent);
