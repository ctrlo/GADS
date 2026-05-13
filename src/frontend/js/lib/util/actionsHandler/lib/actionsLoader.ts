/**
 * Load the actions object from the body data (Base64 encoded JSON)
 * @returns { Promise<string[]> } An object representing the actions or undefined if no actions are defined
 */
const loadActions = async () => {
    const $body = $('body');
    const actions_b64 = $body.data('actions');
    if (typeof actions_b64 == 'undefined') return;
    const action_json = atob(actions_b64);
    const actions = JSON.parse(action_json);
    if (typeof actions == 'undefined') return;
    return actions;
};

export default loadActions;
