import { describe, it, expect } from '@jest/globals';
import loadActions from './actionsLoader';

describe('loadActions', () => {
    it('should return undefined if actions_b64 is undefined', async () => {
        await expect(loadActions()).resolves.toBe(undefined);
    });

    it('should return undefined if action_json is undefined', async () => {
        const $body = $('body');
        $body.data('actions', '');
        await expect(loadActions()).resolves.toBe(undefined);
    });

    it('should return the actions object', async () => {
        const actions_b64 = btoa(JSON.stringify({ action: 'test' }));
        const $body = $('body');
        $body.data('actions', actions_b64);
        await expect(loadActions()).resolves.toEqual({action: 'test'});
    });
});
