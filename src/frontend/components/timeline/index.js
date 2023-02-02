import { initializeComponent, getComponentElements } from 'component'

export default (scope) => {
  if (!getComponentElements(scope, '.timeline').length) {
    return;
  }

  import(
    /* webpackChunkName: "timeline" */
    './lib/component'
  ).then(({ default: Component }) => {
    initializeComponent(scope, '.timeline', Component)
  });
}
