import { initializeComponent } from "../../../js/lib/component";
import SubmitDraftRecordComponent from "./lib/component";

export default (scope) =>
  // eslint-disable-next-line prettier/prettier
  initializeComponent(scope, ".btn-js-submit-draft-record", SubmitDraftRecordComponent);
