import "../../../../../testing/globals.definitions";

import { describe, it, expect } from '@jest/globals';
import { ErrorHandler } from './errorHandler';

describe('ErrorHandler', () => {
    let errorHandler: ErrorHandler;
    let element: HTMLElement;

    beforeEach(() => {
        element = document.createElement('div');
        errorHandler = new ErrorHandler(element);
    });

    it('should initialize with an empty error container', () => {
        expect(errorHandler.errorContainer).toBeDefined();
        expect(errorHandler.errorContainer.children().length).toBe(0);
    });

    it('should add string errors correctly', () => {
        errorHandler.addError('Test error 1', 'Test error 2');
        expect(errorHandler.errorContainer.children().length).toBe(2);
    });

    it('should add Error objects correctly', () => {
        const error1 = new Error('Error object 1');
        const error2 = new Error('Error object 2');
        errorHandler.addError(error1, error2);
        expect(errorHandler.errorContainer.children().length).toBe(2);
    });

    it('should handle unsupported error types gracefully', () => {
        const unsupportedError = { message: 'Unsupported type' };
        console.warn = jest.fn(); // Mock console.warn
        errorHandler.addError(unsupportedError as any);
        expect(console.warn).toHaveBeenCalledWith('Unsupported error type:', unsupportedError);
        expect(errorHandler.errorContainer.children().length).toBe(1);
    });

    it('should clear errors correctly', () => {
        errorHandler.addError('Test error');
        expect(errorHandler.errorContainer.children().length).toBe(1);
        errorHandler.clearErrors();
        expect(errorHandler.errorContainer.children().length).toBe(0);
    });
});
