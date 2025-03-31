import "testing/globals.definitions";
import AutosaveBase from './autosaveBase';

class TestAutosave extends AutosaveBase {
    initAutosave(): void {
        console.log('initAutosave');
    }
}

describe('AutosaveBase', () => {
    beforeAll(() => {
        document.body.innerHTML = `
            <body>
                <div id="test"></div>
            </body>
        `;
        $('body').data('layout-identifier', 1);
    });

    afterAll(()=>{
        document.body.innerHTML = '';
    });

    it('should return layoutId', () => {
        const autosave = new TestAutosave(document.getElementById('test')!);
        expect(autosave.layoutId).toBe(1);
    });

    it('should return recordId', () => {
        const autosave = new TestAutosave(document.getElementById('test')!);
        expect(autosave.recordId).toBe(0);
    });

    it('should return table_key', () => {
        const autosave = new TestAutosave(document.getElementById('test')!);
        expect(autosave.table_key).toBe('linkspace-record-change-1-0');
    });
});
