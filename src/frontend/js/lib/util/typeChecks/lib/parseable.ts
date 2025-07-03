import { isString } from './string';

export const isJsonParseable = (input: unknown): boolean => {
    if (isString(input)) {
        try {
            JSON.parse(input);
            return true;
        } catch {
            return false;
        }
    }
    return false;
}