const createErrorString = (message, source, lineno, colno, error) => {
    let errorString = `Error: ${message}\nSource: ${source}\nLine: ${lineno}, Column: ${colno}`;
    if (error && error.stack) {
        errorString += `\nStack: ${error.stack}`;
    }
    return errorString;
}

window.onerror = function (message: string, source: any, lineno: number, colno: number, error: Error | string | null) {
    console.log("location.pathname", location.pathname);
    if (location.pathname === '/api/script_error' || location.pathname === '/login') {
        // If we're on the script error page, we don't want to log it again.
        console.error("Script error occurred but not logged to avoid recursion.");
        console.error(createErrorString(message, source, lineno, colno, error));
        return;
    }
    const description = createErrorString(message, source, lineno, colno, error)
    console.log("Script error occurred:", description);
    const method = 'N/A';
    const url = window.location.href;
    const body = {
        description,
        method,
        url
    };
    const token = document.body.dataset.csrf;

    // We can just FAF this.
    fetch(`/api/script_error?csrf-token=${token}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(body)
    }).catch(err => {
        console.error("Failed to log script error:", err);
    });
}