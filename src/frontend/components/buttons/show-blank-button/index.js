import { initializeComponent } from "../../../js/lib/component";
import ShowBlankButtonComponent from "./lib/component";

export default (scope) =>
  initializeComponent(scope, ".btn-js-show-blank", ShowBlankButtonComponent);
