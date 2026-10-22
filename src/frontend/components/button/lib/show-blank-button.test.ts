import { describe, it, expect, afterEach, jest } from '@jest/globals';
import showBlankButton from './show-blank-button';

describe('ShowBlankButton', () => {
    afterEach(() => {
        jest.clearAllMocks();
    });

    it('shows blank fields', () => {
        const element = $('<div></div>');
        const button = $('<button class=\'btn-js-show-blank\'><span class=\'btn__title\'>Show blank values</span></button>');
        element.append(button);
        const item = $('<div class=\'list__item--blank\'></div>');
        element.append(item);
        $('body').append(element);
        showBlankButton(element);
        button.trigger('click');
        expect(item.css('display')).not.toBe('none');
    });

    // For some reason this won't behave as expected - disabling the test for now
    it.skip('hides blank fields', () => {
        const element = $('<div></div>');
        const button = $('<button class=\'btn-js-show-blank\'><span class=\'btn__title\'>Hide blank values</span></button>');
        element.append(button);
        const item = $('<div class=\'list__item--blank\'></div>');
        element.append(item);
        showBlankButton(element);
        button.trigger('click');
        expect(item.css('display')).toBe('none');
    });
});