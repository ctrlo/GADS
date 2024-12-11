import { initializeComponent, getComponentElements } from 'component'

export default (scope) => {

  if (!getComponentElements(scope, '.dashboard').length) {
    return;
  }

  import(
    /* webpackChunkName: "dashboard" */
    './lib/component'
  ).then(({ default: DashboardComponent }) => {
    initializeComponent(scope, '.dashboard', DashboardComponent)
  }).then(() => {
    import(
      /* webpackChunkName: "dashboardgraph" */
      './dashboard-graph/lib/component'
    ).then(({ default: DashboardGraphComponent }) => {
      initializeComponent(scope, '.dashboard-graph', DashboardGraphComponent)
    })
  });

}
