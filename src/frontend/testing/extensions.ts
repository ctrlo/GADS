import { expect } from '@jest/globals';

function toHaveAttribute(elm: HTMLElement, attr: string, value: string) {
    if (elm.getAttribute(attr) === value) {
        return {
            pass: true,
            message: () => `Expected element to have attribute ${attr} with value ${value}`
        };
    } else {
        return {
            pass: false,
            message: () => `Expected element to have attribute ${attr} with value ${value}`
        };
    }
}

expect.extend({ toHaveAttribute });
