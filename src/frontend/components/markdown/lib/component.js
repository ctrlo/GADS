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

  //Markdown standard (RFC 7763) states that it is "up to us" according to the use-case to decide what to do with HTML tags,
  //I feel that, under the circumstances, due to any security risks, "script" tags should be removed, and ampersands kept in
  //although any other HTML tags be kept in, as they are not a security risk.
  /**
   * Sanitize any text input to prevent XSS attacks
   * @param {string} text text to sanitize
   * @returns {string} sanitized text
   */
  sanitize(text) {
    if(!text) return text;
    if(text==="") return text;
    return text.replace(/&/g, "&amp;")
      .replace(/<script.*>/g, "script")
      .replace(/<\/script>/g, "/script")
  }
}

export default MarkdownComponent;
