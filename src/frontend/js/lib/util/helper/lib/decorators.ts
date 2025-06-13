import {logging} from "logging";

/**
 * Decorator to log method calls and their results.
 * @param {Function} method - The method to be decorated.
 * @return {Function} A new function that logs the method call and its result.
 */
export const loggedDecorator = (method: (...args: any)=>any) => {
    return function(...args: any) {
        logging.log(`Calling method: ${method.name}`, ...args);
        const result = method.apply(this, args);
        logging.log(`Method ${method.name} returned:`, result);
        return result;
    };
}