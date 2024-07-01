import { do_plot_json } from "../../../graph/lib/chart";
import GraphComponent from "../../../graph/lib/component";

class DashboardGraphComponent extends GraphComponent {
  constructor(element)  {
    super(element);
    this.initDashboardGraph();
  }

  initDashboardGraph() {
    const $graph = $(this.element);
    const graph_data = $graph.data("plot-data");
    const options_in = $graph.data("plot-options");

    do_plot_json(graph_data, options_in);

  }
}

export default DashboardGraphComponent;
