//This is kept for legacy support. Summernote should be used within the Dashboard only, but it is safer to keep this file for now.
import { getComponentElements, initializeComponent } from "component";

export default (scope) => {
    if(!getComponentElements(scope, ".summernote").length) return;
    
    import(/* webpackChunkName: "summernote" */ "./lib/component")
        .then(({default: SummerNoteComponent})=> initializeComponent(scope, ".summernote", SummerNoteComponent));
};
