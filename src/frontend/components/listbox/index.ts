import { getComponentElements, initializeComponent } from 'component';

export default (scope: HTMLElement) => {
    if(getComponentElements(scope, '.togglelist').length) {
        import(/* webpackChunkName: "listbox" */ './lib/component')
            .then(({default: ToggleListComponent})=>{
                //@ts-expect-error - typings on component are incorrect
                initializeComponent(scope, '.togglelist', ToggleListComponent);
            });
    }
}