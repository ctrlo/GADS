import { initializeComponent, getComponentElements } from 'component'

export default (scope) => {
  if (!getComponentElements(scope, '.data-table').length) {
    return;
  }

  import(
    /* webpackChunkName: "datatable" */
    './lib/component' 
  ).then(({ default: Component }) => {
    initializeComponent(scope, '.data-table', Component)
  });
}
