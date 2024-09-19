/**
 * Type for a component class for use in generics
 */
type ComponentLike<T extends Component> = {
  new <TElement extends HTMLElement = HTMLElement>(element: TElement): T
}

/**
 * Base attribute name that's set on a component that's initialized
 */
const componentInitializedAttr = 'component-initialized'

/**
 * The actual attribute name that's set on a component that's initialized.
 * This is appended with the component name, to allow multiple different
 * components to be initialized on the same element.
 */
function componentInitializedAttrName(component_name: string) {
  return `${componentInitializedAttr}-${component_name}`;
}

/**
 * Establish whether a component has already been initialized on an element
 */
function componentIsInitialized(element: HTMLElement, name: string): boolean {
  return $(element).data(componentInitializedAttrName(name)) ? true : false
}

/**
 * Default component class.
 * Components should inherit this class.
 */
export abstract class Component {
  get wasInitialized(): boolean {
    return componentIsInitialized(this.element, this.constructor.name);
  }

  // Whether a component can be reinitialized on an element. For legacy
  // reasons, the default is not to be and initialization will only be run
  // once. For components that set this to true, they must cleanly handle
  // such a reinitialization (returning the object but not resetting up HTML
  // elements etc)
  static allowReinitialization = false;

  constructor(public readonly element: HTMLElement) {
    $(this.element).data(componentInitializedAttrName(this.constructor.name), "true")
  }
}

/**
 * All registered component
 */
const registeredComponents: (<T extends Component>(...args: any[]) => ComponentLike<T>)[] = []

/**
 * Register a component that can be initialized
 *
 * @param componentInitializer Function that will be called when component initializes
 */
export const registerComponent = (componentInitializer: <T extends Component>(...args: any[]) => ComponentLike<T>) => {
  registeredComponents.push(componentInitializer)
}

/**
 * Initialize all registered components in the defined scope
 *
 * @param scope The scope to initialize the components in (either JQuery elements or DOM).
 */
export function initializeRegisteredComponents<T extends HTMLElement = HTMLElement>(scope: T | JQuery<T>) {
  registeredComponents.forEach((componentInitializer) => {
    componentInitializer(scope);
  });
}

/**
 * Get an Array of elements matching `selector` within `scope`
 *
 * @param scope The scope to select elements
 * @param selector The selector to select elements
 * @returns An array of elements
 */
export function getComponentElements<T extends HTMLElement = HTMLElement>(scope: T, selector: string): Array<T | HTMLElement> {
  const elements = scope.querySelectorAll(selector)
  if (!elements.length) return [];

  return Array.from(elements).map((el) => el as T ?? el as HTMLElement);
}

/**
 * Initialize component `Component` on all elements matching `selector` within `scope`
 * Will only initialize elements that have not been initialized.
 *
 * @param {HTMLElement} scope The scope to initialize the objects on
 * @param {string|Function} selector The selector to select elements
 * @param {ComponentLike<T>} ComponentClass The Component class to initialize
 * @returns {Array[T]} An array of initialized components
 */
export const initializeComponent = <T extends Component>(scope: HTMLElement | JQuery<HTMLElement>, selector: string | Function, ComponentClass: ComponentLike<T>): T[] => {
  const scopes = $(scope).get();

  const elements = scopes.flatMap(
    (scope) => typeof (selector) === 'function' ? selector(scope) : getComponentElements(scope, selector)
  )

  if (!elements.length) return []

  return elements
    .filter((el) => {
      return (
        ComponentClass.prototype.allowReinitialization
        // See comments for allowReinitialization()
        || !componentIsInitialized(el, ComponentClass.name)
      )
    }).map((el) => new ComponentClass(el))
}
