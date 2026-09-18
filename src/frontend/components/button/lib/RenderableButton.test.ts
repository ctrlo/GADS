import { describe, it, expect, jest } from '@jest/globals';
import { RenderableButton } from './RenderableButton';

describe('Renderable Button Tests', () => {
    it('should create a Renderable Button', () => {
        const caption = 'Test Button';
        const button = new RenderableButton(caption, ()=>{});

        const rendered = button.render();

        document.body.appendChild(rendered);

        expect(rendered.textContent).toBe('Test Button');
        expect(rendered.classList.contains('btn')).toBeTruthy();
        expect(rendered.classList.contains('btn-default')).toBeTruthy();

        document.body.removeChild(rendered);
    });

    it('should handle click events', () => {
        const mockCallback = jest.fn();
        const button = new RenderableButton('Click Me', mockCallback);

        const rendered = button.render();
        document.body.appendChild(rendered);

        rendered.click();

        expect(mockCallback).toHaveBeenCalled();

        document.body.removeChild(rendered);
    });

    it('should apply custom classes', () => {
        const button = new RenderableButton('Custom Class', ()=>{}, 'btn-custom');

        const rendered = button.render();
        document.body.appendChild(rendered);

        expect(rendered.classList.contains('btn-custom')).toBeTruthy();
        expect(rendered.classList.contains('btn-default')).toBeFalsy();

        document.body.removeChild(rendered);
    });
});