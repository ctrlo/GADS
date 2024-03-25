import { getComponentElements, initializeComponent } from 'component'

export default (scope) => {
    if (!getComponentElements(scope, '.select-widget')) return;
    import(/* webpackChunkName: "select-widget" */ './lib/component')
        .then(({ default: SelectWidgetComponent }) => { initializeComponent(scope, '.select-widget', SelectWidgetComponent) });
}
