import 'util/GadsCharts';
import { Component } from 'component'
import { fromJson } from 'util/common';

class DashboardGraphComponent extends Component {
  constructor(element) {
    super(element)
    this.initDashboardGraph()
  }

  initDashboardGraph() {
    const $graph = $(this.element)
    const data = fromJson(atob($graph.data('plot-data')))
    const settings = fromJson(atob($graph.data('plot-options')))

    $graph.chart({ data, settings })
  }
}

export default DashboardGraphComponent
