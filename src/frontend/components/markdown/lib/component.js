import { Component } from "component";
import MDC from "@davetheitguy/markdown-component";

class MarkdownComponent extends Component {
  constructor(element) {
    super(element);
    this.initMarkdownEditor();
  }

  initMarkdownEditor() {

    const $textArea = $(this.element).find(".js-markdown-input");
    const $preview = $(this.element).find(".js-markdown-preview");

    new MDC($textArea, $preview);
  }
}

export default MarkdownComponent;
