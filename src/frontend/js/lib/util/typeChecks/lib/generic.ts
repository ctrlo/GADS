/**
 * Check if a value is defined (not undefined or null).
 * @param value The value to check
 */
export const isDefined = <T>(value: T | undefined | null): value is T => value !== undefined && value !== null;
