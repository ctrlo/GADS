import { initializeComponent } from "component";

export default (scope) => {
    if(!scope.querySelector(".select")) return;
    import(
        /* webpackChunkName: "select" */ "./lib/component"
    ).then(({ default: SelectComponent }) => {
        initializeComponent(scope, ".select", SelectComponent);
    });
};
