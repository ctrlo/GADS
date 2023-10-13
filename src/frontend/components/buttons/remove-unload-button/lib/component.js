import { Component } from "component";

class RemoveUnloadButtonComponent extends Component {
  constructor(element) {
    super(element);
    this.el = $(this.element);
    this.initRemoveUnload();
  }

  initRemoveUnload() {
    this.el.on("click", () => {
      $(window).off("beforeunload");
    });
  }
}

export default RemoveUnloadButtonComponent;
