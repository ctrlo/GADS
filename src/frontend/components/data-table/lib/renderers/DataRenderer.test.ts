import { describe, it, expect } from '@jest/globals';
import DataRenderer from './DataRenderer';

describe('AbstractRenderer', () => {
    it('should create an instance of IdRenderer for type "id"', () => {
        const renderer = DataRenderer.create({ type: 'id', values: ['123'], base_url: 'http://example.com' });
        const rendered = renderer.render();
        expect(rendered).toBe('<a href="http://example.com/123">123</a>');
    });

    it('should create an instance of DefaultRenderer for type "default"', () => {
        const renderer = DataRenderer.create({ type: 'default', values: ['value1', 'value2'] });
        const rendered = renderer.render();
        expect(rendered).toBe('value1, value2');
    });

    it('should create an instance of FileRenderer for type "file"', () => {
        const renderer = DataRenderer.create({
            type: 'file',
            values: [{ id: 1, name: 'file1.txt', mimetype: 'text/plain' }]
        });
        const rendered = renderer.render();
        expect(rendered).toBe('<a href="/file/1">file1.txt<br></a>');
    });

    it('should create an instance of PersonRenderer for type "person"', () => {
        const renderer = DataRenderer.create({
            type: 'person',
            values: [{ text: 'John Doe', details: [{type: 'email', value: 'j.doe@example.com'}, {definition: 'Name', value: 'John Doe'}] }]
        });
        const rendered = renderer.render();
        // Formatting is /very/ important here, so we need to ensure the HTML structure matches exactly.
        expect(rendered).toBe(`<div class="position-relative">
            <button class="btn btn-small btn-inverted btn-info trigger" aria-expanded="false" type="button">
              John Doe
              <span class="invisible">contact details</span>
            </button>
            <div class="person contact-details expandable popover card card--secundary">
              <div><p>E-mail: <a href="mailto:j.doe@example.com">j.doe@example.com</a></p><p>Name: John Doe</p></div>
            </div>
          </div>`);
    });

    it('should create an instance of DateRenderer for type "date"', () => {
        const renderer = DataRenderer.create({ type: 'date', values: ['2023-10-01'] });
        const rendered = renderer.render();
        expect(rendered).toBe('2023-10-01');
    });

    it('should create an instance of RagRenderer for type "rag"', () => {
        const renderer = DataRenderer.create({ type: 'rag', values: ['red'] });
        const rendered = renderer.render();
        expect(rendered).toBe('<span class="rag rag--blank" title="" aria-labelledby="rag_blank_meaning"><span>✗</span></span>');
    });
});
