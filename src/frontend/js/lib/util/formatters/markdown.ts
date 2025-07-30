import { marked } from 'marked';

type MarkdownCode = string;

type stringLike = { toString(): string };

/**
 * Create a markdown string using template literals.
 * @param { TemplateStringsArray } strings The template strings array containing the static parts of the markdown string.
 * @param { (stringLike | string | number | MarkdownCode)[] } values The values to interpolate into the markdown string. These can be strings, numbers, or objects with a `toString` method.
 * @returns {MarkdownCode} The formatted markdown string, processed by the marked library.
 */
function MarkDown(strings: TemplateStringsArray, ...values: (stringLike | string | number | MarkdownCode)[]): MarkdownCode {
    let str = '';
    for (let i = 0; i < strings.length; i++) {
        str += strings[i];
        if (i < values.length) {
            str += values[i] as string ? values[i] : values[i] as MarkdownCode ? values[i] : values[i] as stringLike ? values[i].toString() : String(values[i]);
        }
    }
    str = str.replace(/\\n/g, '\n\n');
    return marked(str, {breaks: true, async: false}).trim();
}

export { MarkdownCode, MarkDown };
