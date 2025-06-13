/**
 * Interface for a simple logger.
 * It defines methods for logging messages at different levels.
 * The methods can be implemented to log messages to the console or any other logging system.
 * @interface Logger
 */
interface Logger {
    /**
     * Method to log messages at the default level.
     * @param message - The messages to log.
     */
    log: (...message: any[])=>void
    /**
     * Method to log messages at the info level.
     * @param message - The messages to log at the info level.
     */
    info:(...message: any[])=> void
    /**
     * Method to log messages at the warning level.
     * @param message - The messages to log at the info level.
     */
    warn:(...message: any[])=>void
    /**
     * Method to log messages at the error level.
     * @param message - The messages to log at the info level.
     */
    error:(...message: any[])=>void
}

/**
 * Decorator to log method calls and their results.
 * @param {Function} method - The method to be decorated.
 * @return {Function} A new function that logs the method call and its result.
 */
export const loggedDecorator = (logging: Logger, method: (...args: any)=>any) => {
    return function(...args: any) {
        logging.log(`Calling method: ${method.name}`, ...args);
        const result = method.apply(this, args);
        logging.log(`Method ${method.name} returned:`, result);
        return result;
    };
}
