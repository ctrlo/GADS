/**
 * Component class and helper functions for initializing components
 */
type ComponentClassLike<T extends Component> = {
  new(...args: any[]): T;
  allowReinitialization: boolean;
}

/**
 * Base attribute name that's set on a component that's initialized
 */
const componentInitializedAttr = 'component-initialized';

/**
 * The actual attribute name that's set on a component that's initialized.
 * This is appended with the component name, to allow multiple different
 * components to be initialized on the same element.
 */
const componentInitializedAttrName = (component_name: string) => {
  return `${componentInitializedAttr}-${component_name}`;
}

/**
 * Establish whether a component has already been initialized on an element
 */
const componentIsInitialized = (element: HTMLElement, name: string): boolean => {
  return element.getAttribute(componentInitializedAttrName(name)) && true;
}

/**
 * Default component class.
 * Components should inherit this class.
 */
export abstract class Component {
  wasInitialized: boolean;

  // Whether a component can be reinitialized on an element. For legacy
  // reasons, the default is not to be and initialization will only be run
  // once. For components that set this to true, they must cleanly handle
  // such a reinitialization (returning the object but not resetting up HTML
  // elements etc)
  static get allowReinitialization() { return false }

  constructor(public readonly element: HTMLElement) {
    const componentName = this.constructor.name;
    this.wasInitialized = componentIsInitialized(this.element, componentName);
    const attribute = componentInitializedAttrName(componentName);
    $(this.element).data(attribute, "true");
  }
}

/**
 * All registered component
 */
const registeredComponents = [];

/**
 * Register a component that can be initialized
 *
 * @export
 * @param { Function } componentInitializer Function that will be called when component initializes
 */
export const registerComponent = (componentInitializer: (...params: any[]) => void) => {
  registeredComponents.push(componentInitializer);
}

/**
 * Initialize all registered components in the defined scope
 *
 * @export
 * @param {HTMLElement} scope The scope to initialize the components in (either
 *   JQuery elements or DOM).
 */
export const initializeRegisteredComponents = (scope: HTMLElement) => {
  registeredComponents.forEach((componentInitializer) => {
    componentInitializer(scope);
  })
}

/**
 * Get an Array of elements matching `selector` within `scope`
 *
 * @export
 * @param {HTMLElement} scope The scope to select elements
 * @param {String} selector The selector to select elements
 * @returns {Array[HTMLElement]} An array of elements
 */
export const getComponentElements = (scope: HTMLElement, selector: string): HTMLElement[] => {
  const elements = scope.querySelectorAll(selector)
  if (!elements.length) {
    return []
  }

  return Array.from(elements).map((el) => el as HTMLElement);
}

/**
 * Initialize component `Component` on all elements matching `selector` within `scope`
 * Will only initialize elements that have not been initialized.
 *
 * @export
 * @param {HTMLElement} scope The scope to initialize the objects on
 * @param {String|Function} selector The selector to select elements
 * @param {Component} ComponentClass The Component class to initialize
 * @returns {Array[Component]} An array of initialized components
 */
export const initializeComponent = <T extends Component>(scope: HTMLElement | JQuery<HTMLElement>, selector: string | Function, ComponentClass: ComponentClassLike<T>): T[] => {
  const scopes = $(scope).get();

  const elements = scopes.flatMap(
    (scope) => selector instanceof Function ? selector(scope) : getComponentElements($(scope)[0], selector)
  )

  if (!elements.length) {
    return []
  }

  return elements
    .filter((el) => {
      return (
        ComponentClass.allowReinitialization
        // See comments for allowReinitialization()
        || !componentIsInitialized(el, ComponentClass.name)
      )
    }).map((el) => new ComponentClass(el))
}

