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
 * @param component_name The name of the component
 * @returns The attribute name
 */
function componentInitializedAttrName(component_name: string) {
  return `${componentInitializedAttr}-${component_name}`;
}

/**
 * Establish whether a component has already been initialized on an element
 * @param element The element to check
 * @param name The name of the component
 * @returns Whether the component has been initialized
 */
function componentIsInitialized<TElement extends HTMLElement = HTMLElement>(element: TElement, name: string): boolean {
  return $(element).data(componentInitializedAttrName(name)) ? true : false
}

/**
 * Default component class.
 * Components should inherit this class.
 * @template TElement The type of the element that the component is attached to
 */
export abstract class Component<TElement extends HTMLElement = HTMLElement> {
  get wasInitialized(): boolean {
    return componentIsInitialized(this.element, this.constructor.name);
  }

  // Whether a component can be reinitialized on an element. For legacy
  // reasons, the default is not to be and initialization will only be run
  // once. For components that set this to true, they must cleanly handle
  // such a reinitialization (returning the object but not resetting up HTML
  // elements etc)
  static allowReinitialization = false;

  /**
   * Create a new component
   * @param element The element to attach the component to
   */
  constructor(public readonly element: TElement) {
    $(this.element).data(componentInitializedAttrName(this.constructor.name), "true")
  }
}

/**
 * All registered component
 */
const registeredComponents: (<TComponent extends Component>(...args: any[]) => ComponentLike<TComponent>)[] = []

/**
 * Register a component that can be initialized
 * @template TComponent The type of the component
 * @param componentInitializer Function that will be called to initialize the component
 */
export function registerComponent(componentInitializer: <TComponent extends Component>(...args: any[]) => ComponentLike<TComponent>) {
  registeredComponents.push(componentInitializer)
}

/**
 * Initialize all registered components in the defined scope
 * @template TElement The type of the component
 * @param scope The scope to initialize the components in (either JQuery elements or DOM).
 */
export function initializeRegisteredComponents<TElement extends HTMLElement = HTMLElement>(scope: TElement | JQuery<TElement>) {
  registeredComponents.forEach((componentInitializer) => {
    componentInitializer(scope);
  });
}

/**
 * Get an Array of elements matching `selector` within `scope`
 * @template TElement The type of the element
 * @param scope The scope to select elements
 * @param selector The selector to select elements
 * @returns An array of elements
 */
export function getComponentElements<TElement extends HTMLElement = HTMLElement>(scope: TElement, selector: string): Array<TElement | HTMLElement> {
  const elements = scope.querySelectorAll(selector)
  if (!elements.length) return [];

  return Array.from(elements).map((el) => el as TElement ?? el as HTMLElement); // I prefer to ensure that we return something, even though we should never get here
}

/**
 * Initialize component `Component` on all elements matching `selector` within `scope`
 * Will only initialize elements that have not been initialized.
 * @template TComponent The type of the component
 * @template TElement The type of the element
 * @param scope The scope to initialize the objects on
 * @param selector The selector to select elements
 * @param ComponentClass The Component class to initialize
 * @returns An array of initialized components
 */
export function initializeComponent<TComponent extends Component, TElement extends HTMLElement = HTMLElement>(scope: TElement | JQuery<TElement>, selector: string | ((...params: any[]) => any), ComponentClass: ComponentLike<TComponent>): TComponent[] {
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
