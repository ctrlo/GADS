/**
 * This is the main file of the actions handler. These will trigger any actions as they are created in the application.
 */

/**
 * Array of actions to be handled
 */
const actions: (()=>void)[] = [];

/**
 * Add an action to the handler
 * @param action {()=>void} Action to add to the handler
 */
const addAction = (action: () => void) => {
    actions.push(action);
};

/**
 * Handle all actions
 */
const handleActions: () => void = () => {
    actions.forEach(action => action?.());
};

export { addAction, handleActions };