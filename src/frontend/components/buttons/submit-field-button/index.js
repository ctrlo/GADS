import { initializeComponent } from "../../../js/lib/component";
import SubmitFieldComponent from "./lib/component";

export default (scope) =>
  initializeComponent(scope, ".btn-js-submit-field", SubmitFieldComponent);
