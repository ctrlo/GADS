import {initializeComponent, getComponentElements} from 'component'

export default (scope) => {
  if (!getComponentElements(scope, '.modal--new-table').length) {
    return;
  }

  import(
    /* webpackChunkName: "modal" */
    './lib/component'
    ).then(({default: Component}) => {
    initializeComponent(scope, '.modal--new-table', Component)
  });
}
