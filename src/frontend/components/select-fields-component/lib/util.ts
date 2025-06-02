export const isDefined = <T> (value: unknown): value is T => value !== undefined && value !== null;
export const isString = (value: unknown): value is string => isDefined(value) && typeof value === 'string';
export const isEmpty = (value: unknown): value is string => isString(value) && value.trim() === '';
