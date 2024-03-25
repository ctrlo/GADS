import { getComponentElements, initializeComponent } from 'component'

export default (scope) => {
    if(!getComponentElements(scope,'.orderable-sortable')) return

    import(/* webpackChunkName: "orderable" */ "./lib/component")
        .then(({default:OrderableSortableComponent})=> initializeComponent(scope, '.orderable-sortable', OrderableSortableComponent));
}
