import { initializeComponent, getComponentElements } from 'component';

export default (scope) => {

    if (!getComponentElements(scope, '.dashboard').length) {
        return;
    }

    import(
    /* webpackChunkName: "dashboard" */
        './lib/component'
    ).then(({ default: Component }) => {
        initializeComponent(scope, '.dashboard', Component);
    }).then(() => {
        import(
            /* webpackChunkName: "dashboardgraph" */
            './dashboard-graph/lib/component'
        ).then(({ default: Component }) => {
            initializeComponent(scope, '.dashboard-graph', Component);
        });
    });

};
