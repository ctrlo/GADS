import { marked } from "marked";
import { Component } from "component";

class MarkdownComponent extends Component {
  constructor(element) {
    super(element);
    this.initMarkdownEditor();
  }

  renderMarkdown(md) {
    const mdEncoded = $('<span>').text(md).html();
    return marked(mdEncoded);
  }

  initMarkdownEditor() {
    marked.use({ breaks: true });

    const $textArea = $(this.element).find(".js-markdown-input");
    const $preview = $(this.element).find(".js-markdown-preview");
    $().on("ready", () => {
      if ($textArea.val() !== "") {
        const htmlText = this.renderMarkdown($textArea.val());
        $preview.html(htmlText);
      }
    });
    $textArea.keyup(() => {
      const markdownText = $textArea.val();
      if (!markdownText || markdownText === "") {
        $preview.html('<p class="text-info">Nothing to preview!</p>');
      } else {
        const htmlText = this.renderMarkdown(markdownText);
        $preview.html(htmlText);
      }
    });
  }
}

export default MarkdownComponent;
