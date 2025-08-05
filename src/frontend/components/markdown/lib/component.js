import { Component } from 'component';
import { MarkDown } from 'util/formatters/markdown';

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
     * Initialize the markdown editor.
     */
    initMarkdownEditor() {
        const $textArea = $(this.element).find('.js-markdown-input');
        const $preview = $(this.element).find('.js-markdown-preview');
        $().on('ready', () => {
            if ($textArea.val() !== '') {
                const htmlText = MarkDown`${$textArea.val()}`;
                $preview.html(htmlText);
            }
        });
        $textArea.on('keyup',() => {
            const markdownText = $textArea.val();
            if (!markdownText || markdownText === '') {
                $preview.html(MarkDown`Nothing to preview!`);
            } else {
                const htmlText = this.renderMarkdown(markdownText);
                $preview.html(htmlText);
            }
        });
    }
}

export default MarkdownComponent;
