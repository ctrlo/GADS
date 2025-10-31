import { describe, it, expect, beforeEach, afterEach, jest } from '@jest/globals';
import ChronologyButton from './chronology-button';

describe('ChronologyButton', () => {
    afterEach(()=>{
        document.body.innerHTML = '';
        jest.clearAllMocks();
    });

    beforeEach(()=>{
        document.body.innerHTML = `
        <div class="chronology"></div>
            <button id="chronology-button" type="button" class="btn btn-default">
                <span class="icon"></span>
            </button>
        </div>`;
    });

    it('should fire the chronology:loadpage event on click', () => {
        expect.assertions(1);
        const button = document.getElementById('chronology-button')!;
        new ChronologyButton(button);
        const chronology = $('.chronology');
        chronology.on('chronology:loadpage', (event: any) => {
            expect(event.page).toBe(1);
        });
        $(button).trigger('click');
    });
});
