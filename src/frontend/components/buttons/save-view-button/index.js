import { initializeComponent } from "../../../js/lib/component";
import SaveViewButtonComponent from "./lib/component";

export default (scope) =>
  initializeComponent(scope, ".btn-js-submit-record", SaveViewButtonComponent);
