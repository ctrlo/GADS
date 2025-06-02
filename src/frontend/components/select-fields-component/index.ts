import { initializeComponent } from "component";
import SelectFieldsComponent from "./lib/component";

export default (scope) => {
    // @ts-expect-error "initializeComponent" spec is slightly incorrect
    initializeComponent(scope, '.select-fields-component', SelectFieldsComponent)
}
