import { initializeComponent } from "../../../js/lib/component";
import RemoveCurvalButtonComponent from "./lib/component";

export default (scope) =>
  initializeComponent(scope, ".btn-js-curval-remove", RemoveCurvalButtonComponent);
