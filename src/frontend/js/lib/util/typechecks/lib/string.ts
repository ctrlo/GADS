import { isDefined } from "./generic";

export const isString = (value: unknown): value is string => isDefined(value) && typeof value === 'string';
export const isEmptyString = (value: unknown): value is string => isString(value) && value.length === 0;