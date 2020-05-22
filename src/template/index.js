import { setupAccessibility } from "../components/accessibility";
import { setupBuilder } from "../components/builder";
import { setupCalendar } from "../components/calendar";
import { setupColumnFilters } from "../components/column-filters";
import { setupDisclosureWidgets } from "../components/disclosure-widgets";
import { setupEdit } from "../components/edit";
import { setupFileUpload } from "../components/file-upload";
import { setupFirstInputFocus } from "../components/first-input-focus";
import { setupGlobeById } from "../components/globe";
import { setupHtmlEditor } from "../components/html-editor";
import { setupLayout } from "../components/layout";
import { setupLessMoreWidgets } from "../components/less-more-widgets";
import { setupLogin } from "../components/login";
import { setupMetric } from "../components/metric";
import { setupMyGraphs } from "../components/my-graphs";
import { setupPageSpecificCode } from "../components/page-specific-code";
import { setupPlaceholder } from "../components/placeholder";
import { setupPopover } from "../components/popover";
import { setupPurge } from "../components/purge";
import { setupRecordPopup } from "../components/record-popup";
import { setupSelectWidgets } from "../components/select-widgets";
import { setupSubmitListener } from "../components/submit-listener";
import { setupTable } from "../components/table";
import { setupUser } from "../components/user";
import { setupUserPermission } from "../components/user-permission";
import { setupView } from "../components/view";

window.Linkspace = {
  constants: {
      ARROW_LEFT: 37,
      ARROW_RIGHT: 39
  },

  init: function (context) {
      setupAccessibility(context);
      setupBuilder(context);
      setupCalendar(context);
      setupColumnFilters(context);
      setupDisclosureWidgets(context);
      setupEdit(context);
      setupFileUpload(context);
      setupFirstInputFocus(context);
      setupGlobeById(context);
      setupHtmlEditor(context);
      setupLayout(context);
      setupLessMoreWidgets(context);
      setupLogin(context);
      setupMetric(context);
      setupMyGraphs(context);
      setupPageSpecificCode(context);
      setupPlaceholder(context);
      setupPopover(context);
      setupPurge(context);
      setupRecordPopup(context);
      setupSelectWidgets(context);
      setupSubmitListener(context);
      setupTable(context);
      setupUser(context);
      setupUserPermission(context);
      setupView(context);
  },

  debug: function (msg) {
      if (typeof(console) !== 'undefined' && console.debug) {
          console.debug('[LINKSPACE]', msg);
      }
  }
};

window.Linkspace.init();
