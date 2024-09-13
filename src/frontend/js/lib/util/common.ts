export const hideElement = <TElement extends HTMLElement = HTMLElement>(element: TElement | JQuery<TElement>) => {
    $(element).each((_,el) => {
        if (el.classList.contains('hidden')) return;
        el.classList.add('hidden');
        el.setAttribute('aria-hidden', 'true');
    });
};

export const showElement = <TElement extends HTMLElement = HTMLElement>(element: TElement | JQuery<TElement>) => {
    $(element).each((_,el) => {
        if (!el.classList.contains('hidden')) return;
        el.classList.remove('hidden');
        el.removeAttribute('aria-hidden');
    });
};

export const fromJson = <T = object>(json: String | T | null | undefined): T | object => {
    try {
        let result: T = null;
        if (!json || json === '') return {} as object;
        if (typeof json === 'string') {
            result = JSON.parse(json) as T;
        } 
        return result ?? json as T ?? {} as object;
    } catch (e) {
        return {} as object;
    }
}
