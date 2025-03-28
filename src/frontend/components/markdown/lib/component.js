import { marked } from "marked";
import { Component } from "component";

/**
 * Markdown Component
 */
class MarkdownComponent extends Component {
  /**
   * Create a new Markdown Component
   * @param {HTMLElement} element The element to attach the component to
   */
  constructor(element) {
    super(element);
    this.initMarkdownEditor();
  }

  /**
   * Render markdown
   * @param {string} md The markdown to render
   * @returns A string of HTML representing the rendered markdown
   */
  renderMarkdown(md) {
    const mdEncoded = $('<span>').text(md).html()
    return marked(mdEncoded, {async: false});
  }

  /**
   * Initialize the markdown editor
   */
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
    $textArea.on("keyup", () => {
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
