//import { getComponentElements, initializeComponent } from 'component'
import { initializeComponent } from 'component'
import CurvalModalComponent from './lib/component'

export default (scope) => initializeComponent(scope, '.modal--curval', CurvalModalComponent)

//export default (scope) => {
//    if (!getComponentElements(scope, '.modal--curval').length) return;

//    import(/* webpackChunkName="modal" */ "./lib/component")
//        .then(({ default: CurvalModalComponent }) => {
//            initializeComponent(scope, '.modal--curval', CurvalModalComponent)
//        });
//}
