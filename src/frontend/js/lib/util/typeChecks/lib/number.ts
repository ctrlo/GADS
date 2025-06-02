import { isDefined } from "./generic";

/**
 * Check if a value is a number.
 * @param value The value to check
 * @returns {boolean} True if the value is a number, false otherwise
 */
export const isNumber = (value: unknown): value is number => isDefined(value) && typeof value === 'number';

/**
 * Check if a value is a number and is NaN.
 * @param value The value to check
 * @returns {boolean} True if the value is a number and is NaN, false otherwise
 */
export const isNaN = (value: unknown): value is number => isNumber(value) && Number.isNaN(value);

/**
 * Check if a value is a number and not NaN.
 * @param value The value to check
 * @returns {boolean} True if the value is a number and not NaN, false otherwise
 */
export const isNotNaN = (value: unknown): value is number => isNumber(value) && !isNaN(value);

/**
 * Check if a value is a number and is finite.
 * @param value The value to check
 * @returns {boolean} True if the value is a number and is finite, false otherwise
 */
export const isFinite = (value: unknown): value is number => isNumber(value) && Number.isFinite(value);

/**
 * Check if a value is a number and is not finite.
 * @param value The value to check
 * @returns {boolean} True if the value is a number and is not finite, false otherwise
 */
export const isNotFinite = (value: unknown): value is number => isNumber(value) && !isFinite(value);

/**
 * Check if a value is a number and is an integer.
 * @param value The value to check
 * @returns {boolean} True if the value is a number and is an integer, false otherwise
 */
export const isInteger = (value: unknown): value is number => isNumber(value) && Number.isInteger(value);

/**
 * Check if a value is a number and is not an integer.
 * @param value The value to check
 * @returns {boolean} True if the value is a number and is not an integer, false otherwise
 */
export const isNotInteger = (value: unknown): value is number => isNumber(value) && !isInteger(value);
