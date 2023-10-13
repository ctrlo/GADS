import { initializeComponent } from "../../../js/lib/component";
import CalculatorButtonComponent from "./lib/component";

export default (scope) =>
  initializeComponent(scope, ".btn-js-submit-record", CalculatorButtonComponent);
