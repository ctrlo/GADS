import { Component } from "component";

class CalculatorButtonComponent extends Component {
  constructor(element) {
    super(element);
    this.el = $(this.element);
    this.initCalculator();
  }

  initCalculator() {
    //Method was found to be a hanging declaration in original code, will need to be implemented
  }
}

export default CalculatorButtonComponent;
