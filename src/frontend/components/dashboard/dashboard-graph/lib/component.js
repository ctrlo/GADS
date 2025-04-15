import { do_plot_json } from '../../../graph/lib/chart'
import GraphComponent from '../../../graph/lib/component'

/**
 * Graph component for use in the dashboard
 */
class DashboardGraphComponent extends GraphComponent {
  /**
   * Create a new Dashboard graph component
   * @param {HTMLElement} element The element to attach the graph component to
   */
  constructor(element) {
    super(element)
    this.initDashboardGraph()
  }

  /**
   * Initialize the graph component
   */
  initDashboardGraph() {
    const $graph = $(this.element)
    const graph_data = $graph.data('plot-data')
    const options_in = $graph.data('plot-options')

    do_plot_json(graph_data, options_in)

  }
}

export default DashboardGraphComponent
