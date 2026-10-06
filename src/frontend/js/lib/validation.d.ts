declare module "validation" {
    /**
     * Bind events to a field to trigger validation
     * @param field - The field to bind validation events to
     */
    export const initValidationOnField: (field: JQuery<HTMLElement>) => void;

    /**
     * Validate tree
     * @param field The field to validate
     * @returns Returns true if the tree is valid, false otherwise
     */
    export const validateTree: (field: JQuery<HTMLElement>) => boolean;

    /**
     * Validate radio-group
     * @param field The field to validate
     * @returns Returns true if the radio group is valid, false otherwise
     */
    export const validateRadioGroup: (field: JQuery<HTMLElement>) => boolean;

    /**
     * Validate checkbox group
     * @param field The field to validate
     * @returns Returns true if at least one checkbox is checked, false otherwise
     */
    export const validateCheckboxGroup: (field: JQuery<HTMLElement>) => boolean;


    /**
     * Validate the required fields of a form
     * @param form The form to validate
     * @returns Returns true if the form is valid, false otherwise
     */
    export const validateRequiredFields: (form: JQuery<HTMLElement>) => boolean;

    /**
     * Validate query builder inputs
     * @param field The querybuilder to validate
     * @returns False if validation fails, otherwise true on success
     */
    export const validateQueryBuilder: (field: JQuery<HTMLElement>) => boolean;
}
