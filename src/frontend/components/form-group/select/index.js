import { initializeComponent } from "component";

export default (scope) =>
    import("./lib/component")
        .then(({ default: SelectComponent }) => { initializeComponent(scope, ".select", SelectComponent); });
