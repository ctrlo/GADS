declare global {
    interface JQuery<TElement = HTMLElement> {
        queryBuilder(filters:any): JQuery<TElement>;
        queryBuilder(method:string, ...args:any[]): any;
    }
}

export {};