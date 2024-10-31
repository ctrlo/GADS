import {describe, it, expect} from '@jest/globals';
import createCancelButton from './cancel-button';
import "../../../testing/globals.definitions";

describe('CancelButton', () => {
    it('should attach to a button element', () => {
        // Arrange
        const button = document.createElement('button');
        button.classList.add('btn-js-cancel');

        // Act
        createCancelButton(button);

        // Assert
        expect($(button).data('cancel-button')).toEqual('true');
    });

    it('should not attach to a non-button element', () => {
        // Arrange
        const div = document.createElement('div');
        div.classList.add('btn-js-cancel');

        // Act
        createCancelButton(div);

        // Assert
        expect($(div).data('cancel-button')).toBeUndefined();
    });

    it('should remove local storage items when clicked', () => {
        // Arrange
        const button = document.createElement('button');
        button.classList.add('btn-js-cancel');
        const body = document.body;
        body.dataset.layoutIdentifier = 'test';
        const field = document.createElement('div');
        field.classList.add('linkspace-field');
        field.dataset.columnId = '1';
        body.appendChild(field);
        body.appendChild(button);
        const ls = window.localStorage;
        ls.setItem('linkspace-record-change-test', 'test');
        ls.setItem('linkspace-column-1', 'test');

        // Act
        createCancelButton(button);
        button.click();

        // Assert
        expect(ls.getItem('linkspace-record-change-test')).toBeNull();
        expect(ls.getItem('linkspace-column-1')).toBeNull();
    });
});