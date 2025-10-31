import { logging } from 'logging';

/**
 *
 * @param {object} target The target object to decorate
 * @param {(...args: any[])=>any} fn
 * @returns {(...args: any[]) => any}
 */
export const withLogging = (target: object, fn: (...args: any[]) => any): (...args: any[]) => any => {
    return (...args) => {
        logging.info(`Calling ${fn.name} with arguments:`, args);
        try {
            const result = fn.apply(target, args);
            logging.info(`Result from ${fn.name}:`, result);
            return result;
        } catch (error) {
            logging.error(`Error in ${fn.name}:`, error);
            throw error;
        }
    };
};
