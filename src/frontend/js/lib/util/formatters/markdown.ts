import { marked } from "marked";
import { stringLike } from "./types";

type MarkdownCode = string;

/**
 * Create a markdown formatter
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
    return marked(str, {async:false}).trim();
}

export { MarkdownCode, MarkDown };
