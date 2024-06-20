import { initializeComponent, getComponentElements } from 'component';

export default (scope) => {
    if (!getComponentElements(scope, '.display-conditions').length) {
      return;
    }
  
    import(
      /* webpackChunkName: "display-conditions" */
      './lib/component' 
    ).then(({ default: Component }) => {
      initializeComponent(scope, '.display-conditions', Component);
    });
  };