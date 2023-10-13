import { initializeComponent } from "../../../js/lib/component";
import SubmitRecordButtonComponent from "./lib/component";

export default (scope) =>
  initializeComponent(scope, ".btn-js-submit-record", SubmitRecordButtonComponent);
