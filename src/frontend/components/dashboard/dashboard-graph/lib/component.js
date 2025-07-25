import { do_plot_json } from '../../../graph/lib/chart';
import GraphComponent from '../../../graph/lib/component';

/**
 * DashboardGraphComponent class that initializes the dashboard graph and renders the graph using do_plot_json.
 */
class DashboardGraphComponent extends GraphComponent {
    /**
     * Create a DashboardGraphComponent instance.
     * @param {HTMLElement} element The HTML element that this component will be attached to.
     */
    constructor(element) {
        super(element);
        this.initDashboardGraph();
    }

    /**
     * Initialize the dashboard graph by rendering the graph using do_plot_json.
     */
    initDashboardGraph() {
        const $graph = $(this.element);
        const graph_data = $graph.data('plot-data');
        const options_in = $graph.data('plot-options');

        do_plot_json(graph_data, options_in);

    }
}

export default DashboardGraphComponent;
