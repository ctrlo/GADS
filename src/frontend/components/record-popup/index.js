import { getComponentElements, initializeComponent } from 'component';

export default (scope) => {
    if (getComponentElements(scope, '.record-popup').length === 0) return;
    import(/* webpackChunkName: "record-popup" */ './lib/component')
        .then(({ default: RecordPopupComponent }) =>
            initializeComponent(scope, '.record-popup', RecordPopupComponent)
        );
};
