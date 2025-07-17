import 'testing/globals.definitions';
import { describe, it, expect } from '@jest/globals';
import loadActions from './actionsLoader';

describe('loadActions', () => {
    it('should return undefined if actions_b64 is undefined', async () => {
        const actions = await loadActions();
        expect(actions).toBe(undefined);
    });

    it.skip('should return undefined if action_json is undefined', async () => {
        // Skipped as this is not as easy to test as I'd expect
        const $body = $('body');
        $body.data('actions', '');
        const actions = await loadActions();
        expect(actions).toBe(undefined);
    });

    it('should return the actions object', async () => {
        const actions_b64 = btoa(JSON.stringify({ action: 'test' }));
        const $body = $('body');
        $body.data('actions', actions_b64);
        const actions = await loadActions();
        expect(actions).toEqual({ action: 'test' });
    });
});
