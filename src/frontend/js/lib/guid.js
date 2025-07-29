/**
 * Get a new GUID (Globally Unique Identifier).
 * @returns {string} A new GUID (Globally Unique Identifier)
 * @deprecated Use `crypto.randomUUID()` instead if available.
 */
const guid = function () {
    var S4 = function () {
        return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    };
    return (
        S4() +
    S4() +
    '-' +
    S4() +
    '-' +
    S4() +
    '-' +
    S4() +
    '-' +
    S4() +
    S4() +
    S4()
    );
};

export { guid };
