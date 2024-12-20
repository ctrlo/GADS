import "testing/globals.definitions";
import {logging} from "logging";
import {describe, jest, it, expect} from "@jest/globals";

const dom = `
<div>
    <button type="button" class="btn btn-delete btn-small btn-js-delete" data-toggle="modal" data-target="#deleteReport"
        data-title="Test" data-id="1">
        <span class="btn__title">
            Delete
        </span>
    </button>
    <div class="modal modal--delete show" id="deleteReport" tabindex="-1" role="dialog" aria-labelledby="deleteReport]Label"
        aria-modal="true" style="display: block;">
        <div class="modal-dialog modal-dialog-centered " role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <div class="modal-header__content">
                        <h3 class="modal-title" id="deleteReportLabel">UNSET</h3>
                    </div>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true" class="hidden">Close</span>
                    </button>
                </div>

                <form role="form" method="post">
                    <input type="hidden" name="csrf_token" value="NOOP"
                        data-restore-value="NOOP">

                    <div class="modal-frame">
                        <div class="modal-body">
                            <p>Are you sure you wish to delete this report? This cannot be undone.</p>
                        </div>
                        <div class="modal-footer">
                            <div class="modal-footer__left"> <button type="button" class="btn btn-cancel"
                                    data-dismiss="modal">
                                    <span class="btn__title">Cancel</span>
                                </button> </div>
                            <div class="modal-footer__right"> <button type="submit" class="btn btn-danger" name="delete"
                                    value="1">
                                    <span class="btn__title">Delete</span>
                                </button> </div>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
`;

describe('delete button', () => {
    it('should throw an error if id is missing', () => {
        const log = jest.spyOn(logging, 'error');
        const $button = $(document.createElement('button'));
        const element = $button;
        const ev = $.Event('click');
        const createDeleteButton = require('./delete-button').default;
        createDeleteButton(element);
        $button.trigger(ev);
        expect(log).toBeCalledWith('Delete button should have data attributes id, toggle and target!');
    });

    it('should throw an error if target is missing', () => {
        const log = jest.spyOn(logging, 'error');
        const $button = $(document.createElement('button'));
        $button.attr('data-id', '1');
        const element = $button;
        const ev = $.Event('click');
        const createDeleteButton = require('./delete-button').default;
        createDeleteButton(element);
        $button.trigger(ev);
        expect(log).toBeCalledWith('Delete button should have data attributes id, toggle and target!');
    });

    it('should throw an error if toggle is missing', () => {
        const log = jest.spyOn(logging, 'error');
        const $button = $(document.createElement('button'));
        $button.attr('data-id', '1');
        $button.attr('data-target', 'modal');
        const element = $button;
        const ev = $.Event('click');
        const createDeleteButton = require('./delete-button').default;
        createDeleteButton(element);
        $button.trigger(ev);
        expect(log).toBeCalledWith('Delete button should have data attributes id, toggle and target!');
    });

    it('should throw an error if modal is missing', () => {
        const log = jest.spyOn(logging, 'error');
        const $button = $(document.createElement('button'));
        $button.attr('data-id', '1');
        $button.attr('data-target', 'modal');
        $button.attr('data-toggle', 'modal');
        const element = $button;
        const ev = $.Event('click');
        const createDeleteButton = require('./delete-button').default;
        createDeleteButton(element);
        $button.trigger(ev);
        expect(log).toBeCalledWith('There is no modal with id: modal');
    });

    it('should set the modal title', () => {
        const el = $(dom);
        $(document.body).append(el);
        const $button = el.find('button.btn-js-delete');
        console.log($button);
        const element = $button;
        const ev = $.Event('click');
        const createDeleteButton = require('./delete-button').default;
        createDeleteButton(element);
        $button.trigger(ev);
        expect(el.find('.modal-title').text()).toBe('Delete - Test');
    });
});
