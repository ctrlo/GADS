import { describe, it, expect } from '@jest/globals';
import { getPointLabel, getPointValue } from './mappers';
import { PointData } from '../types';

describe('Mappers', () => {
    it('Maps labels', () => {
        const point: PointData = ['Name', 0];
        const expected = 'Name';
        const result = getPointLabel(point);
        expect(result).toBe(expected);
    });

    it('Maps labels from a non-array', () => {
        // @ts-ignore
        const point: PointData = 'Name';
        const expected = 'Name';
        const result = getPointLabel(point);
        expect(result).toBe(expected);
    })

    it('Maps values', () => {
        const point: PointData = ['Name', 0];
        const expected = 0;
        const result = getPointValue(point);
        expect(result).toBe(expected);
    });

    it('Maps values from a non-array', () => {
        // @ts-ignore
        const point: PointData = 0;
        const expected = 0;
        const result = getPointValue(point);
        expect(result).toBe(expected);
    });

    it('Errors on invalid point array on retrieving label', () => {
        const point: PointData = [0, 0];
        expect(() => getPointLabel(point)).toThrow();
    });

    it('Errors on invalid point array on retrieving value', () => {
        const point: PointData = ["foo", "bar"];
        expect(() => getPointValue(point)).toThrow();
    });
});
