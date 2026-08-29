/* eslint-disable */
import "../../../testing/globals.definitions";
import { describe, it, expect } from '@jest/globals';
import {LoadMoreChronologyButton, default as createLoadMoreChronologyButton} from './load-more-chronology-button';

describe('LoadMoreChronologyButton', () => {
    it('should create a button', () => {
        // Mock jQuery elements
        const $button = $('<button data-record-id="123">Load More</button>');
        const $target = $('<div class="chronology"></div>');
        const $spinner = $('<div class="chronology_spinner" style="display:none;"></div>');
        $('body').append($button, $target, $spinner);

        const btn = createLoadMoreChronologyButton($button);

        expect(btn).toBeInstanceOf(LoadMoreChronologyButton);
    });
});
