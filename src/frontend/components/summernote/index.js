import { getComponentElements, initializeComponent } from 'component'

export default (scope) => {
    if(!getComponentElements(scope, '.summernote').length) return;
    
    import(/* webpackChunkName: "summernote" */ "./lib/component")
        .then(({default: SummerNoteComponent})=> initializeComponent(scope, '.summernote', SummerNoteComponent));
}
