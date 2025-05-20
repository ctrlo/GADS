export const isDefined = <T>(value: unknown): value is T => value !== undefined && value !== null;
export const isString = (value: unknown): value is string => isDefined(value) && typeof value === 'string';
export const isNotEmptyString = (value: unknown): value is string => isString(value) && value.trim() !== '';
export const isEmptyString = (value: unknown): value is string => isString(value) && value.trim() === '';

export const hideElement = (element: HTMLElement | JQuery<HTMLElement>) => {
    const $el = $(element);
    if ($el.hasClass('hidden')) return;
    $el.addClass('hidden');
    $el.attr('aria-hidden', 'true');
    $el.css('display', 'none');
    $el.css('visibility', 'hidden');
};

export const showElement = (element: HTMLElement | JQuery<HTMLElement>) => {
    const $el = $(element);
    if (!$el.hasClass('hidden')) return;
    $el.removeClass('hidden');
    $el.removeAttr('aria-hidden');
    $el.removeAttr('style');
};

export const fromJson = (json: String | object) => {
    try {
        if (!json || json === '') return {};
        if (typeof json === 'string') {
            return JSON.parse(json);
        }
        return json;
    } catch (e) {
        return {};
    }
}

export const urlDataToJson = (data: string) => {
    if (isEmptyString(data)) return {};
    const json: any = {};
    if (isString(data)) {
        const params = (<string>data).split('&');
        for (let i = 0; i < params.length; i++) {
            const param = params[i].split('=');
            if (param.length === 2) {
                json[decodeURIComponent(param[0])] = decodeURIComponent(param[1]);
            } else if (param.length === 1) {
                json[decodeURIComponent(param[0])] = '1';
            }
        }
        return json;
    }
}
