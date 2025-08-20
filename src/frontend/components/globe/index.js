import { initializeComponent, getComponentElements } from 'component';

export default (scope) => {
    if (!getComponentElements(scope, '.globe').length) {
        return;
    }

    import(
    /* webpackChunkName: "globe" */
        './lib/component'
    ).then(({ default: Component }) => {
        initializeComponent(scope, '.globe', Component);
    });
};
