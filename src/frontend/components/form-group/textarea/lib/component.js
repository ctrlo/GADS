import { Component } from 'component'
import { initValidationOnField } from 'validation'

class TextareaComponent extends Component {
    constructor(element)  {
      super(element)
      this.el = $(this.element)

      if (this.el.hasClass("textarea--required")) {
        initValidationOnField(this.el)
      }
      
      // Check if there is a textarea with the class 'auto-adjust'
      const $autoAdjustTextarea = this.$el.find('textarea.auto-adjust');
      if ($autoAdjustTextarea.length) {
        this.adjustTextareaHeight();

        $autoAdjustTextarea.on('change', () => {
            this.adjustTextareaHeight();
        });
      }
    } 
    adjustTextareaHeight() {
        const $textarea = this.$el.find('textarea.auto-adjust');

        // Create a hidden div with just the text content
        const $hiddenDiv = $('<div></div>').text($textarea.val()).css({
            visibility: 'hidden',
            position: 'absolute',
            whiteSpace: 'pre-wrap',
            padding: $textarea.css('padding'),
            border: $textarea.css('border'),
        });

        // Add div to body
        $('body').append($hiddenDiv);

        // Calc the height + padding + border
        const contentHeight = $hiddenDiv.outerHeight() / parseFloat(getComputedStyle($hiddenDiv[0]).fontSize);

        // Remove hidden div
        $hiddenDiv.remove();

        const lineHeight = parseFloat($textarea.css('line-height')) / parseFloat($textarea.css('font-size'));
        const minHeight = 2.5; // min height in REM
        const maxHeight = 18;  // max height in REM

        // Calculate the adjusted height
        let adjustedHeight = (contentHeight < minHeight) ? contentHeight : contentHeight + lineHeight;

        // Apply the maximum height constraint
        adjustedHeight = Math.min(adjustedHeight, maxHeight);

        // Set textarea height
        $textarea.css('height', `${adjustedHeight}rem`);
    }
}
export default TextareaComponent
