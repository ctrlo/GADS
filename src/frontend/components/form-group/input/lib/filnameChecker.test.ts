import { describe, it, expect } from '@jest/globals';
import { checkFilename, needsRename } from './filenameChecker';

describe('File name checker', () => {
    it('should flag that a file name needs renaming if it has invalid characters', () => {
        const name = 'file.na#me.txt';
        expect(needsRename(name)).toBeTruthy();
    });

    it('should flag that a file name needs renaming if it has invalid characters in the file name', () => {
        const name = 'f\\i|l/e?n<>a#~m-=-=e.txt';
        expect(needsRename(name)).toBeTruthy();
    });

    it('should flag that a file does not need renaming if it has no invalid characters', () => {
        const name = 'file.txt';
        expect(needsRename(name)).toBeFalsy();
    });

    it('should concatinate if the file name has multiple extensions', () => {
        const name = 'file.name.txt';
        expect(checkFilename(name)).toBe('filename.txt');
    });

    it('should throw an error if the file name has no extension', () => {
        const name = 'file';
        expect(() => checkFilename(name)).toThrowError('Invalid file name - no extension found');
    });

    it('should throw an error if the file name has no file name', () => {
        const name = '.txt';
        expect(() => checkFilename(name)).toThrowError('Invalid file name - no file name found');
    });

    it('should throw an error if the file name has invalid characters in extension', () => {
        const name = 'file.na#me';
        expect(() => checkFilename(name)).toThrowError('Invalid file name - invalid characters in extension');
    });

    it('should return the file name if it is valid', () => {
        const name = 'file.txt';
        expect(checkFilename(name)).toBe('file.txt');
    });

    for (const name of ['filena#me.txt', 'f\\i|l/e?n<>a#~m-=-=e.txt', 'f\\i|l/e?.n<>a#~m-=-=e.txt']) {
        it(`should return the corrected file name with input ${name}`, () => {
            expect(checkFilename(name)).toBe('filename.txt');
        });
    }
});