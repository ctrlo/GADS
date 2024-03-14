import { getComponentElements, initializeComponent } from 'component'

export default (scope) => {
    if(!getComponentElements(scope,'.orderable-sortable')) return

    import(/* webpackChunkName: datatable */ "./lib/component")
        .then(({default:OrderableSortableComponent})=> initializeComponent(scope, '.orderable-sortable', OrderableSortableComponent));
}
