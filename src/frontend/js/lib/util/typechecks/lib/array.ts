import { isDefined } from './generic';

export const isArray = (value: unknown): value is Array<unknown> => isDefined(value) && Array.isArray(value);
