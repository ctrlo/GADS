import { getComponentElements, initializeComponent } from "component";

export default (scope) => {
    if (!getComponentElements(scope, ".calculator").length) return;

    import(/* webpackChunkName: "calculator" */ "./lib/component").then(
        ({ default: CalculatorComponent }) =>
            initializeComponent(scope, ".calculator", CalculatorComponent));
};
