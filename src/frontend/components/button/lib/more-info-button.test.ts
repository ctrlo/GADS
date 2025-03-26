import {expect, it, describe, afterEach, beforeAll} from '@jest/globals';
import createMoreInfoButton from './more-info-button';

const jQuery = $;

(($)=>{ 
    $.fn.load = function() {
        this.text('mocked');
        return this;
    }
})(jQuery);

describe.skip('createMoreInfoButton', () => {
    beforeAll(()=>{
        document.body.innerHTML = '';
    });

    afterEach(()=>{
        document.body.innerHTML = '';
    });

    it('should mock as expected', ()=>{
        const div = $('<div></div>');
        expect(div.load('').text()).toBe('mocked');
    });

    it('should set the title of the modal', ()=>{
        const button = document.createElement('button');
        button.setAttribute('data-record-id', '123');
        button.setAttribute('data-bs-target', '#modal');
        button.classList.add('btn');
        document.body.appendChild(button);
        const modal = document.createElement('div');
        modal.id = 'modal';
        const title = document.createElement('div');
        title.classList.add('modal-title');
        modal.appendChild(title);
        document.body.appendChild(modal);
        createMoreInfoButton(button);
        button.click();
        expect(title.textContent).toBe('Record ID: 123');
    });

    it('should load the record body into the modal', ()=>{
        const button = $('<button data-record-id="123" data-bs-target="#modal" class="btn"></button>');
        button.appendTo(document.body);
        const modal = $(`<div id="modal"><div class="modal-body"></div></div>`);
        modal.appendTo(document.body);
        createMoreInfoButton(button);
        button.trigger('click');
        const $modal = $(document).find('#modal');
        const $body = $modal.find('.modal-body');
        expect($body.text()).toBe('mocked');
    });
});
