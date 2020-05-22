import { do_plot_json } from "../components/chart";
import { setupTimeline } from "../components/timeline";
import { setupGlobeByClass } from "../components/globe";
import { setupTippy } from "../components/tippy";

const IndexPage = context => {
  $(document).ready(function() {
    $(".dashboard-graph", context).each(function() {
      var graph = $(this);
      var graph_data = base64.decode(graph.data("plot-data"));
      var options_in = base64.decode(graph.data("plot-options"));
      do_plot_json(graph_data, options_in);
    });
    $(".visualization", context).each(function() {
      setupTimeline($(this), {});
    });
    $(".globe", context).each(function() {
      setupGlobeByClass($(this));
    });
    setupTippy(context);
  });
};

export { IndexPage };
