import { initializeComponent, getComponentElements } from "component";

export default (scope) => {
    if (!getComponentElements(scope, ".sortable").length) {
        return;
    }

    import(
        /* webpackChunkName: "sortable" */
        "./lib/component" 
    ).then(({ default: Component }) => {
        initializeComponent(scope, ".sortable", Component);
    });
};
  