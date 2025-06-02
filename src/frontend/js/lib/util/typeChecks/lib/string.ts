import { isDefined } from "./generic";

/**
 * Check if a value is a string.
 * @param value The value to check
 * @returns {boolean} True if the value is a string, false otherwise
 */
export const isString = (value: unknown): value is string => isDefined(value) && typeof value === 'string';

/**
 * Check if a value is a string and empty.
 * @param value The value to check
 * @returns {boolean} True if the value is an empty string, false otherwise
 */
export const isEmptyString = (value: unknown): value is string => isString(value) && value.trim() === '';

/**
 * Check if a value is a string and not empty.
 * @param value The value to check
 * @returns True if the value is a string and not empty, false otherwise
 */
export const isNotEmptyString = (value: unknown): value is string => isString(value) && !(isEmptyString(value));
