/**
 * Represents a single frame in a modal flow.
 * @description A Frame holds configuration and DOM references for managing navigation and validation within a multi-step UI process.
 */
class Frame {
    /**
     * Creates a new Frame instance.
     * @param {JQuery<HTMLElement>} frame - The jQuery object representing the frame DOM element.
     * @param {number} previousFrameNumber - The number of the previous frame in the sequence.
     */
    constructor(frame, previousFrameNumber) {
        this.object = frame;
        this.step = frame.data('config').step;
        this.number = frame.data('config').frame;
        this.item = frame.data('config').item || null;
        this.skip = frame.data('config').skip || null;
        this.back = previousFrameNumber;
        this.requiredFields = frame.find('input[required]');
        this.isValid = true;
        this.error = [];
        this.buttons = {
            next: frame.find('.modal-footer .btn-js-next'),
            back: frame.find('.modal-footer .btn-js-back'),
            skip: frame.find('.modal-footer .btn-js-skip'),
            addNext: frame.find('.modal-footer .btn-js-add-next'),
            invisible: frame.find('.modal-footer .btn-js-add-next'),
            save: frame.find('.modal-footer .btn-js-save')
        };
    }
}

export { Frame };
