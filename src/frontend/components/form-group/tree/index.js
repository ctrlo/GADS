import { initializeComponent, getComponentElements } from 'component'

export default (scope) => {
    if (!getComponentElements(scope, '.tree').length) {
      return;
    }
  
    import(
      /* webpackChunkName: "tree" */
      './lib/component' 
    ).then(({ default: Component }) => {
      initializeComponent(scope, '.tree', Component)
    });
  }
  