import { initializeComponent, getComponentElements } from 'component'

export default (scope) => {
    if (!getComponentElements(scope, '.graph').length) {
        return;
    }

    import(
        /* webpackChunkName: "graph" */
        './lib/component'
    ).then(({ default: Component }) => {
        initializeComponent(scope, '.graph', Component)
    });
}