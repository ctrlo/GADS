import { getComponentElements, initializeComponent } from 'component';

export default (scope) => {
    if (getComponentElements(scope, '.dashboard-graph').length === 0) return;
    import('./lib/component').then(({ default: DashboardGraphComponent }) => {
        initializeComponent(scope, '.dashboard-graph', DashboardGraphComponent);
    });
};
