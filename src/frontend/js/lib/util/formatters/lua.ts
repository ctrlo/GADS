import { stringLike } from "./common";

/**
 * Type to represent a string of LUA code.
 */
type LUACode = string;

/**
 * This is currently to purely mark where we expect LUA code to be present
 * @param strings Template to transform into LUA code
 * @param values The values to insert into the LUA code
 * @returns A string of LUA code
 */
function LUA(strings: TemplateStringsArray, ...values: (stringLike | string | number | LUACode)[]): LUACode {
    let str = '';
    for (let i = 0; i < strings.length; i++) {
        str += strings[i];
        if (i < values.length) {
            str += values[i] as string ? values[i] : values[i] as LUACode ? values[i] : values[i] as stringLike ? values[i].toString() : String(values[i]);
        }
    }
    return str;
}

export { LUACode, LUA };
