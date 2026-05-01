import { describe, it, expect } from "@jest/globals";
import { Logging } from "./logging";

describe("Logging", () => {
    describe("Local logging", () => {
        it("should log a message at log level", () => {
            const logger = new Logging(true);
            const consoleFn = jest.fn();
            console.log = consoleFn;
            
            logger.log("This is a log message");
            expect(consoleFn).toHaveBeenCalledWith("This is a log message");
        });

        it("should log a message at info level", () => {
            const logger = new Logging(true);
            const consoleFn = jest.fn();
            console.info = consoleFn;

            logger.info("This is an info message");
            expect(consoleFn).toHaveBeenCalledWith("This is an info message");
        });

        it("should log a message at warn level", () => {
            const logger = new Logging(true);
            const consoleFn = jest.fn();
            console.warn = consoleFn;
            
            logger.warn("This is a warning message");
            expect(consoleFn).toHaveBeenCalledWith("This is a warning message");
        });

        it("should log a message at error level", () => {
            const logger = new Logging(true);
            const consoleFn = jest.fn();
            console.error = consoleFn;

            logger.error("This is an error message");
            expect(consoleFn).toHaveBeenCalledWith("This is an error message");
        });
    });

    describe("Remote logging", () => {
        it("should send a log message to the server", () => {
            const uploadMessage = jest.fn(() =>
                Promise.resolve({
                    ok: true,
                    json: () => Promise.resolve({ success: true }),
                })
            );
            const logger = new Logging(false, uploadMessage);

            logger.log("This is a log message");
            expect(uploadMessage).toHaveBeenCalledWith("log: This is a log message");
        });

        it("should send an info message to the server", () => {
            const uploadMessage = jest.fn(() =>
                Promise.resolve({
                    ok: true,
                    json: () => Promise.resolve({ success: true }),
                })
            );
            const logger = new Logging(false, uploadMessage);

            logger.info("This is an info message");
            expect(uploadMessage).toHaveBeenCalledWith("info: This is an info message");
        });
        
        it("should send a warning message to the server", () => {
            const uploadMessage = jest.fn(() =>
                Promise.resolve({
                    ok: true,
                    json: () => Promise.resolve({ success: true }),
                })
            );
            const logger = new Logging(false, uploadMessage);
            logger.warn("This is a warning message");
            expect(uploadMessage).toHaveBeenCalledWith("warn: This is a warning message");
        });

        it("should send an error message to the server", () => {
            const uploadMessage = jest.fn(() =>
                Promise.resolve({
                    ok: true,
                    json: () => Promise.resolve({ success: true }),
                })
            );
            const logger = new Logging(false, uploadMessage);
            logger.error("This is an error message");
            expect(uploadMessage).toHaveBeenCalledWith("error: This is an error message");
        });
    });
});
