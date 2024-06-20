import { initializeComponent, getComponentElements } from 'component';

export default (scope) => {
    if (!getComponentElements(scope, '.filter').length) {
      return;
    }
  
    import(
      /* webpackChunkName: "filter" */
      './lib/component' 
    ).then(({ default: Component }) => {
      initializeComponent(scope, '.filter', Component);
    });
  };
  