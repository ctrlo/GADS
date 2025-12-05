import "../../../../../testing/globals.definitions";
import { describe, it, expect } from '@jest/globals';
import { clearAutorecoverAction } from './clearAutorecoverAction';
import StorageProvider from "../../storageProvider/lib/storageProvider";

describe('clearAutorecoverAction', () => {
    it('Should not action if layout-identifier is undefined', async () => {
        await expect(clearAutorecoverAction()).resolves.toBe(false);
    });

    it('Should not action if actions object is undefined', async () => {
        $('body').data('layout-identifier', 'test');
        await expect(clearAutorecoverAction()).resolves.toBe(false);
    });

    it('Should not action if clear_saved_values is not in actions object', async () => {
        $('body').data('layout-identifier', 'test');
        $('body').data('actions', btoa(JSON.stringify({})));
        await expect(clearAutorecoverAction()).resolves.toBe(false);
    });

    it('Should clear storage provider', async () => {
        $('body').data('layout-identifier', 'test');
        $('body').data('actions', btoa(JSON.stringify({ clear_saved_values: 1 })));
        const storage = new StorageProvider('linkspace-record-change-test-1');
        await storage.setItem('key', 'value');
        await expect(clearAutorecoverAction()).resolves.toBe(true);
        await expect(storage.getItem('key')).resolves.toBe(undefined);
    });
});
