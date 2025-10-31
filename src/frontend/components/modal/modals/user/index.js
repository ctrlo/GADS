import { getComponentElements, initializeComponent } from 'component';

export default (scope) => {
    if (!getComponentElements(scope, '.modal--user').length) return;
    import(/* webpackChunkName: "modal" */ './lib/component')
        .then(({ default: UserModalComponent }) => initializeComponent(scope, '.modal--user', UserModalComponent));
};
