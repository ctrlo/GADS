/**
 * Map an object or FormData to a FormData object.
 * @param {FormData | T} data The data to be mapped, either FormData or an object
 * @template T The type of the data being mapped
 * @throws {Error} If the data is empty or not a valid FormData or object
 * @returns {FormData} The mapped FormData object
 */
export const formdataMapper = <T extends object>(data: FormData | T): FormData => {
    if (data instanceof FormData) {
        let hasData = false;
        data.forEach(() => {
            hasData = true;
            return;
        });
        if (!hasData) throw new Error('Cannot map an empty object');
        return data;
    }
    if (data instanceof Object && Object.keys(data).length === 0) throw new Error('Cannot map an empty object');
    const formData = new FormData();
    Object.entries(data).forEach(([key, value]) => {
        formData.append(key, value);
    });
    return formData;
};
