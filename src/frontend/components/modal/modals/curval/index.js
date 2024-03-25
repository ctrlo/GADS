import { getComponentElements, initializeComponent } from 'component'

export default (scope) => {
    if (!getComponentElements(scope, '.modal--curval').length) return;

    import(/* webpackChunkName="modal" */ "./lib/component")
        .then(({ default: CurvalModalComponent }) => {
            initializeComponent(scope, '.modal--curval', CurvalModalComponent)
        });
}
