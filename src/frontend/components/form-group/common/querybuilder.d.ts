declare global {
    interface JQuery<TElement = HTMLElement> {
        queryBuilder(filters:any): JQuery<TElement>;
    }
}

export {};