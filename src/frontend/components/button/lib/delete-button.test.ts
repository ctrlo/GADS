import { describe, it, expect } from '@jest/globals';
import createDeleteButton from './delete-button';

describe('button tests', () => {
    it('should throw on absence of id', () => {
        const button = document.createElement('button');
        button.setAttribute('data-title', 'title');
        button.setAttribute('data-target', 'target');
        button.setAttribute('data-toggle', 'toggle');
        document.body.appendChild(button);
        const $button = $(button);
        createDeleteButton($button)
        expect(() => { $button.trigger('click') }).toThrow('Delete button should have data attributes id, toggle and target!');
    });

    it('should throw on absence of target', () => {
        const button = document.createElement('button');
        button.setAttribute('data-title', 'title');
        button.setAttribute('data-id', 'id');
        button.setAttribute('data-toggle', 'toggle');
        document.body.appendChild(button);
        const $button = $(button);
        createDeleteButton($button);
        expect(() => { $button.trigger('click') }).toThrow('Delete button should have data attributes id, toggle and target!');
    });

    it('should throw on absence of toggle', () => {
        const button = document.createElement('button');
        button.setAttribute('data-title', 'title');
        button.setAttribute('data-id', 'id');
        button.setAttribute('data-target', 'target');
        document.body.appendChild(button);
        const $button = $(button);
        createDeleteButton($button);
        expect(() => { $button.trigger('click') }).toThrow('Delete button should have data attributes id, toggle and target!');
    });

    it('should set the title of the modal', () => {
        const button = document.createElement('button');
        button.setAttribute('data-title', 'title');
        button.setAttribute('data-id', 'id');
        button.setAttribute('data-target', 'target');
        button.setAttribute('data-toggle', 'toggle');
        document.body.appendChild(button);
        const modal = document.createElement('div');
        modal.classList.add('modal--deletetarget');
        const title = document.createElement('div');
        title.classList.add('modal-title');
        modal.appendChild(title);
        document.body.appendChild(modal);
        const $button = $(button);
        createDeleteButton($button);
        $button.trigger('click');
        expect($(modal).find('.modal-title').text()).toBe('Delete - title');
    });

    it('should set the id of the delete button', () => {
        const button = document.createElement('button');
        button.setAttribute('data-title', 'title');
        button.setAttribute('data-id', 'id');
        button.setAttribute('data-target', 'target');
        button.setAttribute('data-toggle', 'toggle');
        document.body.appendChild(button);
        const modal = document.createElement('div');
        modal.classList.add('modal--deletetarget');
        const title = document.createElement('div');
        title.classList.add('modal-title');
        modal.appendChild(title);
        const submit = document.createElement('button');
        submit.setAttribute('type', 'submit');
        modal.appendChild(submit);
        document.body.appendChild(modal);
        const $button = $(button);
        createDeleteButton($button);
        $button.trigger('click');
        expect($(modal).find('button[type=submit]').val()).toBe('id');
    })
});
