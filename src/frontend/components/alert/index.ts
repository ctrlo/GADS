import { initializeComponent } from "component"
import AlertComponent from "./lib/component"

export default (scope) =>{
    // @ts-expect-error The components are not typesafe
    initializeComponent(scope, '.alert', AlertComponent)
}