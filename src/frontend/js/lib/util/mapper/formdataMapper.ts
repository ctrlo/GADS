/**
 * Map a JSON object to FormData.
 * This function takes a JSON object or a FormData object and converts it to a FormData object.
 * If the input is already a FormData object, it checks if it is empty and throws an error if it is.
 * @param data The data to map to FormData. This can be a FormData object or an object with key-value pairs.
 * @throws Error if the data is empty.
 * @returns The formdata object.
 */
export const formdataMapper = <T>(data: FormData | T) => {
    if (data instanceof FormData) {
        let hasData = false;
        data.forEach(() => {
            hasData = true;
            return;
        });
        if (!hasData) throw new Error("Cannot map an empty object");
        return data;
    }
    if (data instanceof Object && Object.keys(data).length === 0) throw new Error("Cannot map an empty object");
    const formData = new FormData();
    Object.entries(data).forEach(([key, value]) => {
        formData.append(key, value);
    });
    return formData;
}