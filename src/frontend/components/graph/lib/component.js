import { Component } from 'component';
import "util/GadsCharts";

class GraphComponent extends Component {
  constructor(element) {
    super(element);
    this.initGraph();    
  }

  initGraph() {
    const $el = $(this.element).find('.graph__container');
    const layoutId = $el.data('layout-id');
    const graphId = $el.data('graph-id');
    const url = this.getURL(layoutId, graphId);
    fetch(url)
      .then(response => response.json())
      .then(data=>$el.chart(data));
  }

  getURL(layoutId, graphId) {
    const time = new Date().getTime()
    return `/${layoutId}/data_graph/${graphId}/${time}`
  }
}

export default GraphComponent
