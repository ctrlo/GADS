import { marked } from "marked";
import { stringLike } from "./common";

/**
 * MarkdownCode is a type that represents a string that contains Markdown content.
 */
type MarkdownCode = string;

/**
 * This is a function to transform a template string into a Markdown code.
 * @param strings Template to transform into Markdown code
 * @param values The values to insert into the Markdown code
 * @returns A string of Markdown code
 */
function MarkDown(strings: TemplateStringsArray, ...values: (stringLike | string | number | MarkdownCode)[]): MarkdownCode {
    marked.use({ breaks: true })
    let str = '';
    for (let i = 0; i < strings.length; i++) {
        str += strings[i];
        if (i < values.length) {
            str += values[i] as string ? values[i] : values[i] as MarkdownCode ? values[i] : values[i] as stringLike ? values[i].toString() : String(values[i]);
        }
    }
    str = str.replace(/\\n/g, '\n\n');
    return marked(str).trim();
}

export { MarkdownCode, MarkDown };
