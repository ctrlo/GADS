import { isObject } from "vis-util";
import { hasProperty, isJsonParseable, isString } from "../../typeChecks";
import { fromJson } from "../../common";

export const createErrorMessage = (input: any): string => {
    if(isString(input)) {
        if(isJsonParseable(input)) {
            const parsed = fromJson(input);
            return isObject(parsed) && hasProperty(parsed, 'message') ? isString(parsed.message) ? parsed.message : JSON.stringify(parsed): JSON.stringify(parsed);
        } else {
            return input;
        }
    } else if (isObject(input)) {
        if(hasProperty(input, 'message')) {
            return isString(input.message) ? input.message : JSON.stringify(input);
        } else {
            return JSON.stringify(input);
        }
    } else {
        throw new Error("Invalid input type");
    }
}
