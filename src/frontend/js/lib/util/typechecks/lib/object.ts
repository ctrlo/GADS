import { isDefined } from './generic';

export const isObject = (value: unknown): value is Record<string, unknown> => isDefined(value) && typeof value === 'object' && !Array.isArray(value);
export const hasMethod = (value: unknown, methodName: string): value is { [key: string]: unknown } & { [method: string]: (...args: any[]) => any } =>
    isObject(value) && methodName in value && typeof value[methodName] === 'function';
