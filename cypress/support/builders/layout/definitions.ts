import { LayoutType } from "./types";

interface DropdownOptions {
    values: string[];
}

export type LayoutDefinition = {
    [key in LayoutType]?: {
        name: string;
        shortName: string;
        options?: DropdownOptions;
        data?: string | { from: string, to: string };
    }
}

interface FilterDefinition {
    field: string;
    operator: string;
    value: string;
    typeahead?: boolean;
}

export interface ViewDefinition {
    name: string;
    filters: FilterDefinition[];
    sort?: string;
    group?: string;
    fields: string[];
}
