import { marked } from "marked";
import { Component } from "../../../js/lib/component";

class MarkdownComponent extends Component {
  constructor(element) {
    super(element);
    this.initMarkdownEditor();
  }

  initMarkdownEditor() {
    marked.use({ breaks: true });

    const $textArea = $(this.element).find(".js-markdown-input");
    const $preview = $(this.element).find(".js-markdown-preview");
    $().ready(() => {
      if ($textArea.val() !== "") {
        const htmlText = marked($textArea.val());
        $preview.html(htmlText);
      }
    });
    $textArea.keyup(() => {
      const markdownText = $textArea.val();
      if (!markdownText || markdownText === "") {
        $preview.html('<p class="text-info">Nothing to preview!</p>');
      } else {
        const htmlText = marked(markdownText);
        $preview.html(htmlText);
      }
    });
  }
}

export default MarkdownComponent;
