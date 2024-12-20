import initDateField from "components/datepicker/lib/helper";
import InputBase from "./inputBase";

class DateComponent extends InputBase {
  readonly type = 'date';
  
  init() {
    initDateField(this.input);
  }
}

const dateComponent = (el: JQuery<HTMLElement> | HTMLElement) => {
  const component = new DateComponent(el);
  component.init();
  return component;
}

export default dateComponent;