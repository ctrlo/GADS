/**
 * get the value from a field, depending on its type
 * @param $depends - The jQuery object representing the field
 * @param filtered - Whether the field is filtered
 * @param for_code - Whether to return the value for code generation
 * @param for_autosave - Whether to return the value for autosave
 * @returns The value(s) of the field, formatted according to the field type
 */
declare const getFieldValues: <TElement extends HTMLElement = HTMLElement>($depends: JQuery<TElement>, filtered: boolean, for_code: boolean, for_autosave: boolean) => string | Array<any> | object;
