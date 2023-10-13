import { initializeComponent } from "../../../js/lib/component";
import { MoreInfoButton } from "./lib/more-info-button";

export default (scope) =>
  initializeComponent(scope, ".btn-js-more-info", MoreInfoButton);
