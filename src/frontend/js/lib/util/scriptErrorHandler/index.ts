import { uploadMessage } from "./lib/MessageUploader";

const createErrorString = (message: string, source: any, lineno: number, colno: number, error: Error | undefined) => {
    let errorString = `Error: ${message}\nSource: ${source}\nLine: ${lineno}, Column: ${colno}`;
    if (error && (error as Error)?.stack) {
        errorString += `\nStack: ${(error as Error)?.stack}`;
    }
    return errorString;
};

window.onerror = function (message: string| Event, source: any, lineno: number | undefined, colno: number | undefined, error: Error | undefined) {
    if (location.host === "localhost" || message instanceof Event) {
        // If we're on localhost, we log the error to the console. This is useful for development.
        console.error("Script error occurred:", message, source, lineno, colno, error);
    }
    // We should never trigger this, but it's to stop TS6 arguing!
    if (message instanceof Event) return;
    if (location.pathname === "/api/script_error" || location.pathname === "/login") {
        // If we're on the script error page, we don't want to log it again.
        console.error("Script error occurred but not logged to avoid recursion.");
        console.error(createErrorString(message, source, lineno || 0, colno || 0, error));
        return;
    }

    const description = createErrorString(message, source, lineno || 0, colno || 0, error);

    uploadMessage(description)
        .catch(err => {
            console.error("Failed to upload script error:", err);
        });
};

export { uploadMessage };
