import { ConfigPage } from "../pages/config";
import { DataCalendarPage } from "../pages/data-calendar";
import { DataGlobePage } from "../pages/data-globe";
import { DataGraphPage } from "../pages/data-graph";
import { DataTablePage } from "../pages/data-table";
import { DataTimelinePage } from "../pages/data-timeline";
import { EditPage } from "../pages/edit";
import { GraphPage } from "../pages/graph";
import { GraphsPage } from "../pages/graphs";
import { IndexPage } from "../pages/index";
import { LayoutPage } from "../pages/layout";
import { MetricPage } from "../pages/metric";
import { PurgePage } from "../pages/purge";
import { SytemPage } from "../pages/system";
import { UserPage } from "../pages/user";

const setupPageSpecificCode = (() => {
  const pages = {
    config: ConfigPage,
    data_calendar: DataCalendarPage,
    data_globe: DataGlobePage,
    data_graph: DataGraphPage,
    data_table: DataTablePage,
    data_timeline: DataTimelinePage,
    edit: EditPage,
    graph: GraphPage,
    graphs: GraphsPage,
    index: IndexPage,
    layout: LayoutPage,
    metric: MetricPage,
    purge: PurgePage,
    system: SytemPage,
    user: UserPage
  }

  const setupPageSpecificCode = context => {
    var page = $('body').data('page').match(/^(.*?)(:?\/\d+)?$/);
    if (page === null) {
      return;
    }

    var setupPageComponent = pages[page[1]];
    if (setupPageComponent !== undefined) {
      setupPageComponent(context);
    }
  };

  return context => {
    setupPageSpecificCode(context);
  };
})()

export { setupPageSpecificCode };
