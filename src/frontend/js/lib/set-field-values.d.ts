/**
 * Set the value of a field based on its type.
 * @param $field The field to set values for
 * @param values The values to set for the field
 */
declare const setFieldValues: <TElement extends HTMLElement = HTMLElement>($field: JQuery<TElement>, value: (string | object)[]) => void;
