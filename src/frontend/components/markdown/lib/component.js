import { marked } from "marked";
import { Component } from "component";

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
        const markdownText = this.sanitize($textArea.val())
        const htmlText = marked(markdownText);
        $preview.html(htmlText);
      }
    });
    $textArea.keyup(() => {
      const markdownText = this.sanitize($textArea.val());
      if (!markdownText || markdownText === "") {
        $preview.html('<p class="text-info">Nothing to preview!</p>');
      } else {
        const htmlText = marked(markdownText);
        $preview.html(htmlText);
      }
    });
  }

  //This is very basic, but I feel it would be 1) easy to extend and 2) enough for our use-case
  sanitize(text) {
    if(!text) return text;
    if(text==="") return text;
    return text.replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;")
  }
}

export default MarkdownComponent;
