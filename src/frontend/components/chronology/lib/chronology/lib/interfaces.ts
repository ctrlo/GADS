import { ChronologyActionType, ChronologyCreateAction, ChronologyUpdateAction } from "./types";

/**
 * ChronologyAction defines the structure of an action that can be performed on a chronology entry.
 */
export interface ChronologyAction {
    /**
     * The type of action that can be performed on a chronology entry.
     * It can be either "create" or "update".
     */
    type: ChronologyActionType;
    /**
     * The datetime when the action was performed.
     */
    datetime: string;
    /**
     * The user who performed the action.
     */
    user: string;
}

/**
 * Chronology defines the structure of a chronology entry.
 */
export interface Chronology {
    /**
     * The chronology entry.
     * This can be a create action or an update action.
     */
    data: ChronologyCreateAction | ChronologyUpdateAction;
    /**
     * The action performed on the chronology entry.
     * It includes the type of action and the details of the action.
     */
    action: ChronologyAction;
}

export interface ChronologyUpdate extends Chronology {
    action: ChronologyAction & { type: "update"; };
    data: ChronologyUpdateAction;
}

export interface ChronologyCreate extends Chronology {
    action: ChronologyAction & { type: "create"; };
    data: ChronologyCreateAction;
}

export interface ChronologyResult {
    /**
     * The current page number of the chronology results.
     */
    page: number;
    /**
     * The last page number of the chronology results.
     */
    last_page: number;
    /**
     * The list of chronology entries returned by the API.
     */
    result: Chronology[];
}

export interface TypedObject {
    type: string;
}

export interface Person extends TypedObject {
    type: "person";
    id: number;
    text: string;
    details: { [key: string]: string }[];
}
