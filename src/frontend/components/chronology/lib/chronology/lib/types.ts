/**
 * ChronologyActionType defines the type of action that can be performed on a chronology entry.
 */
export type ChronologyActionType = "create" | "update";

/**
 * ChronologyAction defines the structure of an action that can be performed on a chronology entry.
 * It includes the type of action and the details of the action.
 */
export type ChronologyCreateAction = { [key: string]: string | { [key: string]: string } | null };

/**
 * ChronologyUpdateAction defines the structure of an update action on a chronology entry.
 */
export type ChronologyUpdateAction =
    {
        [key: string]: {
            old: string | null;
            new: string | null;
        }
    };
