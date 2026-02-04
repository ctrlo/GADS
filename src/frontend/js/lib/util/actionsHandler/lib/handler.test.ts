import { describe, it, expect, jest } from "@jest/globals"
import { addAction, handleActions } from './handler';

describe('addAction', () => {
    it('should add an action to the list of actions', () => {
        const action = jest.fn();
        addAction(action);
        expect(() => handleActions()).not.toThrow();
        expect(action).toHaveBeenCalled();
    });
});
