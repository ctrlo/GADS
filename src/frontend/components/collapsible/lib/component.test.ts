import {describe, it, expect, beforeEach, afterEach} from '@jest/globals';
import Collapsible from './component';

describe('Collapsible', () => {
    beforeEach(() => {
        document.body.innerHTML = `
        <div id="target" class="collapsible">
            <div class="form-group">
            <button type="button" class="btn btn-default btn-block btn-collapsible" data-toggle="collapse" aria-expanded=false data-target=#content aria-controls=#content>
                <span class="btn__title btn__title--collapsed">Reveal</span>
                <span class="btn__title btn__title--expanded">Hide</span>
            </button>
            </div>
            <div id="content" class="collapse">
            <div class="readonly readonly--center">
                <span class="readonly__label">Content is:</span>
                <span class="readonly__value">content</span>
            </div>
            <div class="attention">Please make a secure note of this content now, as it will not be displayed again.</div>
            </div>
        </div>
  `;
    });

    afterEach(() => {
        document.body.innerHTML = '';
    });

    it('should create a new collapsible component', () => {
        const target = document.getElementById('target');
        expect(target).not.toBeNull();
        expect(target?.dataset.componentInitializedCollapsiblecomponent).not.toBe('true');
        new Collapsible(target as HTMLElement);
        expect(target?.dataset.componentInitializedCollapsiblecomponent).toBe('true');
    });

    it('should toggle the collapsible content', () => {
        const target = document.getElementById('target');
        if(target === null) throw new Error('Target element not found');
        new Collapsible(target as HTMLElement);
        const button = target.querySelector('.btn-collapsible') as HTMLButtonElement;
        const titleCollapsed = target.querySelector('.btn__title--collapsed') as HTMLSpanElement;
        const titleExpanded = target.querySelector('.btn__title--expanded') as HTMLSpanElement;
        // Initial state
        expect(titleCollapsed.classList.contains('hidden')).toBe(false);
        expect(titleExpanded.classList.contains('hidden')).toBe(true);
        // Toggle
        button.click();
        expect(titleCollapsed.classList.contains('hidden')).toBe(true);
        expect(titleExpanded.classList.contains('hidden')).toBe(false);
        // Toggle again
        button.click();
        expect(titleCollapsed.classList.contains('hidden')).toBe(false);
        expect(titleExpanded.classList.contains('hidden')).toBe(true);
    });
});