import {initializeComponent} from "component";
import SelectRevealComponent from "./lib/component";

// @ts-expect-error typings on Component are not correct
export default (scope: any) => initializeComponent(scope, ".select-reveal", SelectRevealComponent);
