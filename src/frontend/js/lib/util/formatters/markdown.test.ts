import { MarkDown } from "./markdown";

describe("Markdown formatter tests", ()=>{
    it("Should return empty string", ()=>{
        const expected = "";
        const result = MarkDown``;
        expect(result).toBe(expected);
    });

    it("Should return basic string with formatted value when no markdown is given", ()=>{
        const expected = "<p>test</p>";
        const result = MarkDown`test`;
        expect(result).toBe(expected);
    });

    it("Should return properly formatted text", ()=>{
        const expected = "<h1>test</h1>";
        const result = MarkDown`# test`;
        expect(result).toBe(expected);
    });

    it("Should return properly formatted text with various inputs", ()=>{
        const expected = "<h1>test</h1>\n<p>test <em>test</em></p>";
        const result = MarkDown`# test\ntest *test*`;
        expect(result).toBe(expected);
    });

    it("Should return properly formatted text with newlines", ()=>{
        const expected = "<h1>test</h1>\n<p>test</p>\n<p>test</p>";
        const result = MarkDown`# test\\ntest\\ntest`;
        expect(result).toBe(expected);
    });
});
