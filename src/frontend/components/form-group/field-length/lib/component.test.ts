import {describe, it, expect} from "@jest/globals";
import FieldLengthComponent from "./component";

describe("FieldLengthComponent", () => {
    it("should error when not passed the correct type of component", () => {
        const div = document.createElement("div");
        expect(() => new FieldLengthComponent(div)).toThrow("Element must be a textarea or input");
    });

    it("should not create a counter if the element lacks the data-max attribute", () => {
        const input = document.createElement("input");
        document.body.appendChild(input);
        new FieldLengthComponent(input);
        const counter = input.nextElementSibling as HTMLElement;
        expect(counter).toBeNull();
    });

    it("should create a counter with the correct values when the input is empty", () => {
        const input = document.createElement("input");
        input.dataset.max = "10";
        document.body.appendChild(input);
        new FieldLengthComponent(input);
        const counter = input.nextElementSibling as HTMLElement;
        expect(counter).not.toBeNull();
        expect(counter.textContent).toBe("0/10");
    });

    it("should create a counter with the correct values when the input has some text", () => {
        const input = document.createElement("input");
        input.dataset.max = "10";
        input.value = "Hello";
        document.body.appendChild(input);
        new FieldLengthComponent(input);
        const counter = input.nextElementSibling as HTMLElement;
        expect(counter).not.toBeNull();
        expect(counter.textContent).toBe("5/10");
    });

    it("should update the counter with the correct values when the input value changes", () => {
        const input = document.createElement("input");
        input.dataset.max = "10";
        document.body.appendChild(input);
        new FieldLengthComponent(input);
        const counter = input.nextElementSibling as HTMLElement;
        expect(counter).not.toBeNull();
        input.value = "Hello";
        input.dispatchEvent(new Event("keyup"));
        expect(counter.textContent).toBe("5/10");
    });

    it("should add the invalid class to the counter when the input value exceeds the max length", () => {
        const input = document.createElement("input");
        input.dataset.max = "10";
        document.body.appendChild(input);
        new FieldLengthComponent(input);
        const counter = input.nextElementSibling as HTMLElement;
        expect(counter).not.toBeNull();
        input.value = "Hello World!";
        input.dispatchEvent(new Event("keyup"));
        expect(counter.classList.contains("invalid")).toBe(true);
    });

    it("should remove the invalid class from the counter when the input value is reduced to be within the max length", () => {
        const input = document.createElement("input");
        input.dataset.max = "10";
        document.body.appendChild(input);
        new FieldLengthComponent(input);
        const counter = input.nextElementSibling as HTMLElement;
        expect(counter).not.toBeNull();
        input.value = "Hello World!";
        input.dispatchEvent(new Event("keyup"));
        expect(counter.classList.contains("invalid")).toBe(true);
        input.value = "Hello";
        input.dispatchEvent(new Event("keyup"));
        expect(counter.classList.contains("invalid")).toBe(false);
    });

    it("Should work with textarea elements", () => {
        const textarea = document.createElement("textarea");
        textarea.dataset.max = "10";
        document.body.appendChild(textarea);
        new FieldLengthComponent(textarea);
        const counter = textarea.nextElementSibling as HTMLElement;
        expect(counter).not.toBeNull();
        textarea.value = "Hello World!";
        textarea.dispatchEvent(new Event("keyup"));
        expect(counter.classList.contains("invalid")).toBe(true);
    });
});
