import { isObject } from './object';

export const hasProperty = <T extends object, K extends PropertyKey>(obj: T, key: K): obj is T & Record<K, unknown> => isObject(obj) && key in obj;
