import { initializeComponent } from "component";
import EditableText from "./lib/component";

export default (scope) => initializeComponent(scope, '.js-editable-text', EditableText);