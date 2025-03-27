/**
 * Map data to formdata
 * @param data The data to map
 * @returns {FormData} The mapped data as formdata
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