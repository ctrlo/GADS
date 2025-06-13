import {describe, it, expect} from '@jest/globals';
import { itemRenderer } from './renderer';

describe('itemRenderer', () => {
    it('should render a timeline item with content', () => {
        const args = {
            content: 'Test content; More details',
            current_id: 1,
            values: [{ name: 'Value1', value: 'Data1' }, { name: 'Value2', value: 'Data2' }]
        };
        const element = itemRenderer(args);
        
        expect(element.tagName).toBe('DIV');
        expect(element.className).toBe('timeline-tippy');
        expect(element.getAttribute('data-tippy-content')).toContain('Record 1');
        expect(element.innerText).toBe('Test content');
    });

    it('should handle empty content gracefully', () => {
        const args = {
            content: '',
            current_id: 2,
            values: []
        };
        const element = itemRenderer(args);
        
        expect(element.innerText).toBe('No content provided');
    });

    it('should render Tippy content correctly', () => {
        const args = {
            current_id: 3,
            values: [{ name: 'Value1', value: 'Data1' }],
            content: 'Tippy content for Record 3;'
        };
        const tippyContent = itemRenderer(args).getAttribute('data-tippy-content');
        
        expect(tippyContent).toContain('<b>Record 3</b>');
        expect(tippyContent).toContain('<li>Value1: Data1</li>');
    });
});