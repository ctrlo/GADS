/**
 * Base attribute name that's set on a component that's initialized
 */
const componentInitializedAttr = 'data-component-initialized';

/**
 * The actual attribute name that's set on a component that's initialized.
 * @description This is appended with the component name, to allow multiple different components to be initialized on the same element.
 * @param {string} component_name The name of the component
 * @returns {string} The attribute name for the component
 */
const componentInitializedAttrName = (component_name) => {
    return componentInitializedAttr + '-' + component_name;
};

/**
 * Establish whether a component has already been initialized on an element
 * @param {HTMLElement} element The element to check
 * @param {string} name The name of the component
 * @returns {boolean} True if the component has been initialized, false otherwise
 */
const componentIsInitialized = (element, name) => {
    return element.getAttribute(componentInitializedAttrName(name)) ? true : false;
};

/**
 * Default component class.
 * Components should inherit this class.
 */
class Component {

    /**
     * Whether a component can be reinitialized on an element. For legacy
     * reasons, the default is not to be and initialization will only be run
     * once. For components that set this to true, they must cleanly handle
     * such a reinitialization (returning the object but not resetting up HTML
     * elements etc)
     * @returns {boolean} True if the component can be reinitialized, false otherwise
     * @static
     */
    static get allowReinitialization() { return false; }

    /**
     * Create a new component instance.
     * @param {HTMLElement} element The element to initialize the component on
     * @throws {Error} If the element is not an HTMLElement
     */
    constructor(element) {
        if (!(element instanceof HTMLElement)) {
            throw new Error(
                'Components can only be initialized with an HTMLElement as argument to the constructor'
            );
        }

        this.element = element;
        this.wasInitialized = componentIsInitialized(this.element, this.constructor.name);
        this.element.setAttribute(componentInitializedAttrName(this.constructor.name), true);
    }
}

/**
 * All registered components
 * @type {Array[Function]}
 */
const registeredComponents = [];

/**
 * Register a component that can be initialized
 * @param { Function } componentInitializer Function that will be called when component initializes
 */
const registerComponent = (componentInitializer) => {
    registeredComponents.push(componentInitializer);
};

/**
 * Initialize all registered components in the defined scope
 * @param {HTMLElement | JQuery<HTMLElement>} scope The scope to initialize the components in (either JQuery elements or DOM).
 */
const initializeRegisteredComponents = (scope) => {
    registeredComponents.forEach((componentInitializer) => {
        componentInitializer(scope);
    });
};

/**
 * Get an Array of elements matching `selector` within `scope`
 * @param {HTMLElement} scope The scope to select elements
 * @param {string} selector The selector to select elements
 * @returns {Array[HTMLElement]} An array of elements
 */
const getComponentElements = (scope, selector) => {
    const elements = scope.querySelectorAll(selector);
    if (!elements.length) {
        return [];
    }

    return Array.from(elements);
};

/**
 * Initialize component `Component` on all elements matching `selector` within `scope`
 * Will only initialize elements that have not been initialized.
 * @param {HTMLElement} scope The scope to initialize the objects on
 * @param {string|Function} selector The selector to select elements
 * @param {Component} ComponentClass The Component class to initialize
 * @returns {Array[Component]} An array of initialized components
 */
const initializeComponent = (scope, selector, ComponentClass) => {
    if (!(ComponentClass.prototype instanceof Component)) {
        throw new Error(
            'Components can only be initialized when they inherit the basecomponent'
        );
    }

    const scopes = (scope instanceof jQuery) ? scope.get() : [scope];

    const elements = scopes.flatMap(
        (scope) => typeof (selector) === 'function' ? selector(scope) : getComponentElements(scope, selector)
    );

    if (!elements.length) {
        return [];
    }

    return elements
        .filter((el) => {
            return (
                ComponentClass.allowReinitialization
        // See comments for allowReinitialization()
        || !componentIsInitialized(el, ComponentClass.name)
            );
        }).map((el) => new ComponentClass(el));
};

export {
    Component,
    initializeComponent,
    initializeRegisteredComponents,
    getComponentElements,
    registerComponent
};
