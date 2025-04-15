import { marked } from "marked";
import { Component } from "component";

/**
 * Component to render a preview of markdown text.
 */
class MarkdownComponent extends Component {
  /**
   * Create a new MarkdownComponent.
   * @param {HTMLElement} element The element to attach the component to.
   */
  constructor(element) {
    super(element);
    this.initMarkdownEditor();
  }

  /**
   * Render markdown text to HTML.
   * @param {string} md The markdown to render.
   * @returns {string} The rendered HTML.
   */
  renderMarkdown(md) {
    const mdEncoded = $('<span>').text(md).html()
    return marked(mdEncoded);
  }

  /**
   * Initialize the markdown editor.
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
