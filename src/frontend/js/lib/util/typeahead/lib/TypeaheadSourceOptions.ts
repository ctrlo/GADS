import { MapperFunction } from 'util/mapper/mapper';

export class TypeaheadSourceOptions {
    constructor(
        public name: string,
        public ajaxSource: string,
        public mapper: MapperFunction,
        public appendQuery: boolean,
        public data: any,
        public dataBuilder: (...args: any[]) => any,
        public method: 'GET' | 'POST' = 'GET') {
    }
}
