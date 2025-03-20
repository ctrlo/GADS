import { describe, it, expect, jest, beforeEach, afterEach } from '@jest/globals';
import createSelectAllButton from './select-all-button';

describe('createSelectAllButton', () => {
    beforeEach(() => {
        const div = document.createElement('div');
        div.classList.add('togglelist');
        const box = document.createElement('input');
        box.type = 'checkbox';
        div.appendChild(box);
        const button = document.createElement('button');
        button.type = 'button';
        div.appendChild(button);
        document.body.appendChild(div);
    });

    afterEach(() => {
        document.body.innerHTML = '';
    });

    it('Errors without an action', ()=>{
        const button = document.querySelector('button') as HTMLElement;
        expect(() => createSelectAllButton(button)).toThrowError('Invalid data-action value');
    });

    it('Checks all checkboxes when action is check', ()=>{
        const button = document.querySelector('button') as HTMLElement;
        button.dataset.action = 'check';
        const checkbox = document.querySelector('input[type="checkbox"]') as HTMLInputElement;
        checkbox.checked = false;
        createSelectAllButton(button);
        button.click();
        expect(checkbox.checked).toBe(true);
    });

    it('Unchecks all checkboxes when action is uncheck', ()=>{
        const button = document.querySelector('button') as HTMLElement;
        button.dataset.action = 'uncheck';
        const checkbox = document.querySelector('input[type="checkbox"]') as HTMLInputElement;
        checkbox.checked = true;
        createSelectAllButton(button);
        button.click();
        expect(checkbox.checked).toBe(false);
    });

    it('Fires the change event on the checkbox', ()=>{
        expect.assertions(2);
        const fn = jest.fn((ev:JQuery.ClickEvent)=>{
            expect(ev.target.checked).toBe(true);
        });
        const button = document.querySelector('button') as HTMLElement;
        button.dataset.action = 'check';
        const checkbox = document.querySelector('input[type="checkbox"]') as HTMLInputElement;
        checkbox.checked = false;
        //@ts-ignore
        $(checkbox).on('change', fn);
        createSelectAllButton(button);
        button.click();
        expect(fn).toHaveBeenCalled();
    });
});