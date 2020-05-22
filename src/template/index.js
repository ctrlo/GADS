import { setupBuilder } from "../components/builder";
import { setupCalendar } from "../components/calendar";
import { setupEdit } from "../components/edit";
import { setupGlobe } from "../components/globe";
import { setupGraph } from "../components/graph";
import { setupLayout } from "../components/layout";
import { setupLogin } from "../components/login";
import { setupMetric } from "../components/metric";
import { setupMyGraphs } from "../components/my-graphs";
import { setupPlaceholder } from "../components/placeholder";
import { setupPopover } from "../components/popover";
import { setupPurge } from "../components/purge";
import { setupTable } from "../components/table";
import { setupUser } from "../components/user";
import { setupUserPermission } from "../components/user-permission";
import { setupView } from "../components/view";

const setupJSFromContext = context => {

  var page = $('body').data('page');

  setupBuilder(context);
  setupCalendar(context);
  setupEdit(context);
  setupGlobe(context);
  if (page == "data_graph") {
      $(document).ready(function(){ // jqplot does not work in IE8 unless in document.ready
          setupGraph(context);
      });
  }
  setupLayout(context);
  setupLogin(context);
  setupMetric(context);
  setupMyGraphs(context);
  setupPlaceholder(context);
  setupPopover(context);
  setupPurge(context);
  setupTable(context);
  setupUser(context);
  setupUserPermission(context);
  setupView(context);
};

setupJSFromContext();
