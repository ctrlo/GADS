import { isDefined } from "./generic";

export const isString = (input: unknown): input is string => isDefined(input) && typeof input === 'string';
