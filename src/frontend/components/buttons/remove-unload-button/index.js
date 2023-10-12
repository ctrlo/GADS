import { initializeComponent } from "../../../js/lib/component";
import RemoveUnloadButtonComponent from "./lib/component";

export default (scope) =>
  initializeComponent(scope, ".btn-js-remove-unload", RemoveUnloadButtonComponent);
