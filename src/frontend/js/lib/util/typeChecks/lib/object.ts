import { isDefined } from './generic';

export const isObject = (input: unknown): input is Record<string, unknown> => isDefined(input) && typeof input === 'object' && !Array.isArray(input);
