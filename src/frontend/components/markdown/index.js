import {getComponentElements, initializeComponent} from "component";

export default (scope) => {
  if (getComponentElements(scope, ".js-markdown-section").length === 0) return;

  import(/* webpackChunkName: "markdown" */ "./lib/component")
    .then(({default: MarkdownComponent}) => {
      initializeComponent(scope, ".js-markdown-section", MarkdownComponent)
    });
}
