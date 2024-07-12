import { getComponentElements, initializeComponent } from "component"

export default (scope) => {
    if(!getComponentElements(scope,".people-filter").length) return;

    import(/* webpackChunkName: "people-filter" */ "./lib/component").then(({default: component}) => {
        initializeComponent(scope, ".people-filter", component);
    });
}