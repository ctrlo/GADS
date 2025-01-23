import {expect} from '@jest/globals';

function toHaveAttribute(elm: HTMLElement, attr: string, value: string) {
    if(elm.getAttribute(attr) === value) {
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

function toHaveNumberOfMenuItems(elm: HTMLElement, count: number) {
    const menu = elm.parentElement.querySelector('.dropdown__list');
    const result = menu?.querySelectorAll('.dropdown__item').length;
    if(result === count) {
        return {
            pass: true,
            message: () => `Expected element to have ${count} menu items`
        };
    } else {
        return {
            pass: false,
            message: () => `Expected element to have ${count} menu items, item has ${result ?? 0}`
        };
    }
}

expect.extend({ toHaveAttribute, toHaveNumberOfMenuItems });