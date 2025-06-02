import {describe, it, expect} from '@jest/globals';
import * as NumberChecks from './number';

describe('Number Checks', () => {
    it('isNumber', () => {
        expect(NumberChecks.isNumber(42)).toBe(true);
        expect(NumberChecks.isNumber(NaN)).toBe(true);
        expect(NumberChecks.isNumber(Infinity)).toBe(true);
        expect(NumberChecks.isNumber(-Infinity)).toBe(true);
        expect(NumberChecks.isNumber('42')).toBe(false);
        expect(NumberChecks.isNumber(null)).toBe(false);
        expect(NumberChecks.isNumber(undefined)).toBe(false);
    });
    
    it('isNaN', () => {
        expect(NumberChecks.isNaN(NaN)).toBe(true);
        expect(NumberChecks.isNaN(42)).toBe(false);
        expect(NumberChecks.isNaN(Infinity)).toBe(false);
        expect(NumberChecks.isNaN(-Infinity)).toBe(false);
        expect(NumberChecks.isNaN('NaN')).toBe(false);
    });
    
    it('isNotNaN', () => {
        expect(NumberChecks.isNotNaN(42)).toBe(true);
        expect(NumberChecks.isNotNaN(NaN)).toBe(false);
        expect(NumberChecks.isNotNaN(Infinity)).toBe(true);
        expect(NumberChecks.isNotNaN(-Infinity)).toBe(true);
    });
    
    it('isFinite', () => {
        expect(NumberChecks.isFinite(42)).toBe(true);
        expect(NumberChecks.isFinite(NaN)).toBe(false);
        expect(NumberChecks.isFinite(Infinity)).toBe(false);
        expect(NumberChecks.isFinite(-Infinity)).toBe(false);
    });
    
    it('isNotFinite', () => {
        expect(NumberChecks.isNotFinite(42)).toBe(false);
        expect(NumberChecks.isNotFinite(NaN)).toBe(true);
        expect(NumberChecks.isNotFinite(Infinity)).toBe(true);
        expect(NumberChecks.isNotFinite(-Infinity)).toBe(true);
    });
    
    it('isInteger', () => {
        expect(NumberChecks.isInteger(42)).toBe(true);
        expect(NumberChecks.isInteger(42.5)).toBe(false);
    });
    
    it('isNotInteger', () => {
        expect(NumberChecks.isNotInteger(42.5)).toBe(true);
        expect(NumberChecks.isNotInteger(42)).toBe(false);
    });
});