/* eslint-disable @typescript-eslint/no-unused-vars */
import "../../../testing/globals.definitions";
import {describe, it, expect, jest} from '@jest/globals';
import {BaseButton} from './base-button';

class TestButton extends BaseButton {
    type = 'btn-js-test';

    click(ev: JQuery.ClickEvent): void {
        console.log('TestButton clicked');
    }

    init(): void {
        console.log('TestButton initialized');
    }
}

const createTestButton = (element: JQuery<HTMLElement>) => {
    return new TestButton(element);
};

describe('BaseButton', () => {
    it('Should be able to create class and trigger click', () => {
        const spy = jest.spyOn(console, 'log').mockImplementation((text)=>{});
        const b = $('<button></button>');
        const button = createTestButton(b);
        expect(button).toBeTruthy();
        expect(button).toBeInstanceOf(TestButton);
        expect(button.type).toBe('btn-js-test');
        -expect(spy).toHaveBeenCalledWith('TestButton initialized');
        b.trigger('click');
        expect(spy).toHaveBeenCalledWith('TestButton clicked');
        jest.restoreAllMocks();
    });
});
