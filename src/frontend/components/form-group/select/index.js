import { getComponentElements, initializeComponent } from "component";

export default (scope) => {
    if(!getComponentElements(scope, ".select")) return;

    import(
        /* webpackChunkName: "select-component" */ "./lib/component"
    ).then(({ default: SelectComponent }) => {
        initializeComponent(scope, ".select", SelectComponent);
    });
};
