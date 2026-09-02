import { uploadMessage } from "./lib/MessageUploader";

const createErrorString = (message: string, source: any, lineno: number, colno: number, error: Error | string | null) => {
    let errorString = `Error: ${message}\nSource: ${source}\nLine: ${lineno}, Column: ${colno}`;
    if (error && (error as Error)?.stack) {
        errorString += `\nStack: ${(error as Error)?.stack}`;
    }
    return errorString;
};

window.onerror = function (message: string, source: any, lineno: number, colno: number, error: Error | string | null) {
    if (location.host === "localhost") {
        // If we're on localhost, we log the error to the console. This is useful for development.
        console.error("Script error occurred:", message, source, lineno, colno, error);
    }
    if (location.pathname === "/api/script_error" || location.pathname === "/login") {
        // If we're on the script error page, we don't want to log it again.
        console.error("Script error occurred but not logged to avoid recursion.");
        console.error(createErrorString(message, source, lineno, colno, error));
        return;
    }

    const description = createErrorString(message, source, lineno, colno, error);

    uploadMessage(description)
        .catch(err => {
            console.error("Failed to upload script error:", err);
        });
};

export { uploadMessage };
