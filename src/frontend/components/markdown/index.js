import { initializeComponent } from "../../js/lib/component";
import MarkdownComponent from "./lib/component";

export default (scope) =>
  initializeComponent(scope, ".js-markdown-section", MarkdownComponent);
