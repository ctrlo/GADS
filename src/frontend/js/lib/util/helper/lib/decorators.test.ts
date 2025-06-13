import { describe, it, expect } from '@jest/globals';
import { loggedDecorator } from './decorators';

describe('loggedDecorator', () => {
    const mockLogger = {
        log: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
    };

    it('should log method calls and results', () => {
        const testMethod = (a, b) => a + b;
        const decoratedMethod = loggedDecorator(mockLogger, testMethod);

        const result = decoratedMethod(2, 3);

        expect(mockLogger.log).toHaveBeenCalledWith('Calling method: testMethod', 2, 3);
        expect(mockLogger.log).toHaveBeenCalledWith('Method testMethod returned:', 5);
        expect(result).toBe(5);
    });

    it('should handle methods with no arguments', () => {
        const testMethod = () => 'no args';
        const decoratedMethod = loggedDecorator(mockLogger, testMethod);

        const result = decoratedMethod();

        expect(mockLogger.log).toHaveBeenCalledWith('Calling method: testMethod');
        expect(mockLogger.log).toHaveBeenCalledWith('Method testMethod returned:', 'no args');
        expect(result).toBe('no args');
    });
});
