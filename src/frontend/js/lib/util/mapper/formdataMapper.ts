export const formdataMapper = <T>(data: FormData | T) => {
    if (data instanceof FormData) {
        let hasData = false;
        data.forEach(() => {
            hasData = true;
            return;
        });
        if(!hasData) throw new Error("Cannot map an empty object");
        return data;
    }
    if(data instanceof Object && Object.keys(data).length === 0) throw new Error("Cannot map an empty object");
    const formData = new FormData();
    Object.entries(data).forEach(([key, value]) => {
        if (value instanceof Object) {
            Object.entries(value).forEach(([subKey, subValue]) => {
                if(subValue instanceof Object) throw new Error("Nested objects deeper than one layer are not supported");
                formData.append(`${key}_${subKey}`, subValue as string);
            });
        } else {
            formData.append(key, value as string);
        }
    });
    return formData;
}