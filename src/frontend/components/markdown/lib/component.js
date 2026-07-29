import { MarkDown } from 'util/formatters/markdown';
import { Component } from 'component';

/**
 * Component for rendering markdown text.
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
     * @param {string} md The markdown text to render.
     * @returns {string} The rendered HTML.
     */
    renderMarkdown(md) {
        const mdEncoded = $('<span>').text(md)
            .html();
        return MarkDown`${mdEncoded}`;
    }

    /**
     * Initialize the markdown editor.
     */
    initMarkdownEditor() {
        const $textArea = $(this.element).find('.js-markdown-input');
        const $preview = $(this.element).find('.js-markdown-preview');
        $(document).on('ready', () => {
            if ($textArea.val() !== '') {
                const htmlText = this.renderMarkdown($textArea.val());
                $preview.html(htmlText);
            }
        });
        $textArea.on('keyup', () => {
            const markdownText = $textArea.val();
            if (!markdownText || markdownText === '') {
                $preview.html('<p class="text-info">Nothing to preview!</p>');
            } else {
                const htmlText = this.renderMarkdown(markdownText);
                $preview.html(htmlText);
            }
        });
    }
}

export default MarkdownComponent;
