/**
 * Array of actions to be handled
 */
const actions: (() => void)[] = [];

/**
 * Add an action to the handler
 * @param action Action to add to the handler
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