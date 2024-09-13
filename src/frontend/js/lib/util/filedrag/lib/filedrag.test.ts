import "../../../../../testing/globals.definitions";
import { FileDrag } from './filedrag';

class FileDragTest extends FileDrag<HTMLDivElement> {
    constructor(element: HTMLDivElement, onDrop?: (files: FileList | File) => void) {
        super(element, { debug: window.test ? true : false }, onDrop);
    }

    setDragging(dragging: boolean) {
        this.dragging = dragging;
    }

    getDragging() {
        return this.dragging;
    }
}

describe('FileDrag class tests', () => {
    function createBaseDOM() {
        const div = document.createElement('div');
        const child = document.createElement('div');
        child.className = 'documentChild';
        div.append(child);
        document.body.append(div);
        return child;
    }

    it('creates a new file drag instance', () => {
        const fileDrag = new FileDragTest(document.createElement('div'));
        expect(fileDrag).toBeDefined();
        expect(fileDrag).toBeInstanceOf(FileDrag);
    });

    it('sets dragging to true when document dragenter event is fired', () => {
        const fileDrag = new FileDragTest(document.createElement('div'));
        expect(fileDrag.getDragging()).toBeFalsy();
        const e = $.Event('dragenter');
        $(document).trigger(e);
        expect(fileDrag.getDragging()).toBeTruthy();
    });

    it('sets dragging to false when document dragleave event is fired', () => {
        const fileDrag = new FileDragTest(document.createElement('div'));
        fileDrag.setDragging(true);
        expect(fileDrag.getDragging()).toBeTruthy();
        const e = $.Event('dragleave', { originalEvent: { pageX: 0, pageY: 0 } });
        $(document).trigger(e);
        expect(fileDrag.getDragging()).toBeFalsy();
    });

    it('hides the correct element when dragging starts', () => {
        //Who said testing was boring? This is fun!
        const child = createBaseDOM();
        const fileDrag = new FileDragTest(child);
        const parent = child.parentElement;
        expect(parent).toBeDefined();
        const dropZone = parent!.querySelector('.drop-zone');
        expect(dropZone).toBeDefined();
        expect(fileDrag.getDragging()).toBeFalsy();
        expect(child.getAttribute('aria-hidden')).toBeFalsy();
        expect(child.classList.contains('hidden')).toBeFalsy();
        const e = $.Event('dragenter');
        $(document).trigger(e);
        expect(fileDrag.getDragging()).toBeTruthy();
        expect(child.getAttribute('aria-hidden')).toBe('true');
        expect(child.classList.contains('hidden')).toBeTruthy();
    });

    it('shows the correct element when dragging ends', () => {
        const child = createBaseDOM();
        new FileDragTest(child);
        const parent = child.parentElement;
        expect(parent).toBeDefined();
        const dropZone = parent!.querySelector('.drop-zone');
        expect(dropZone).toBeDefined();
        const e = $.Event('dragenter');
        $(document).trigger(e);
        const e2 = $.Event('dragleave', { originalEvent: { pageX: 0, pageY: 0, stopPropagation: jest.fn() } });
        $(document).trigger(e2);
        expect(child.getAttribute('aria-hidden')).toBeFalsy();
        expect(child.classList.contains('hidden')).toBeFalsy();
    });

    it('creates the correct drop zone element', () => {
        const child = createBaseDOM();
        new FileDragTest(child);
        const parent = child.parentElement;
        expect(parent).toBeDefined();
        const dropZone = parent!.querySelector('.drop-zone');
        expect(dropZone).toBeDefined();
        expect(dropZone!.classList.contains('drop-zone')).toBeTruthy();
        expect(dropZone!.classList.contains('hidden')).toBeTruthy();
        expect(dropZone!.getAttribute('aria-hidden')).toBe('true');
    });

    it('triggers the event as expected when a file is dropped', () => {
        const child = createBaseDOM();
        const dropFunction = jest.fn((files) => {
            const myFile = files;
            expect(myFile).toBeDefined();
            expect(myFile.name).toBe('test.txt');
        });
        const fileDrag = new FileDragTest(child, (file) => dropFunction(file));
        fileDrag.setDragging(true);
        const parent = child.parentElement;
        expect(parent).toBeDefined();
        const dropZone = parent!.querySelector('.drop-zone');
        expect(dropZone).toBeDefined();
        const e = $.Event('drop', { originalEvent: { dataTransfer: { files: [{ name: 'test.txt' }] } }, stopPropagation: jest.fn() });
        $(dropZone!).trigger(e);
        expect(dropFunction).toHaveBeenCalled();
    });
});
