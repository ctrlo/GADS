import { initializeComponent, getComponentElements } from 'component'

export default (scope) => {
    if (!getComponentElements(scope, '.sortable').length) {
        return;
    }

    import(
        /* webpackChunkName: "datatable" */
        './lib/component' 
    ).then(({ default: Component }) => {
        initializeComponent(scope, '.sortable', Component)
    });
}
  