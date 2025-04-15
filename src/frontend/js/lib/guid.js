/**
 * Create a unique identifier (GUID).
 * @returns {string} A unique identifier in the form of a GUID (Globally Unique Identifier).
 * @deprecated This function is deprecated. Use ctrypto.randomUUID() instead.
 */
const guid = function () {
  var S4 = function () {
    return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
  };
  return (
    S4() +
    S4() +
    "-" +
    S4() +
    "-" +
    S4() +
    "-" +
    S4() +
    "-" +
    S4() +
    S4() +
    S4()
  );
};

export { guid };
