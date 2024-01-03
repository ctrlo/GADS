/**
 * Base attribute name that's set on a component that's initialized
 */
const componentInitializedAttr = 'data-component-initialized'

/**
 * The actual attribute name that's set on a component that's initialized.
 * This is appended with the component name, to allow multiple different
 * components to be initialized on the same element.
 */
const componentInitializedAttrName = (component_name) => {
  return componentInitializedAttr + "-" + component_name;
}

/**
 * Default component class.
 * Components should inherit this class.
 */
class Component {
  constructor(element) {
    if (!(element instanceof HTMLElement)) {
      throw new Error(
        'Components can only be initialized with an HTMLElement as argument to the constructor',
      )
    }

    this.element = element
    this.element.setAttribute(componentInitializedAttrName(this.constructor.name), true)
  }
}

/**
 * All registered component
 */
const registeredComponents = []

/**
 * Register a component that can be initialized
 *
 * @export
 * @param { Function } componentInitializer Function that will be called when component initializes
 */
const registerComponent = (componentInitializer) => {
  registeredComponents.push(componentInitializer)
}

/**
 * Initialize all registered components in the defined scope
 *
 * @export
 * @param {HTMLElement} scope The scope to initialize the components in.
 */
const initializeRegisteredComponents = (scope) => {
  registeredComponents.forEach((componentInitializer) => {
    componentInitializer(scope)
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
const getComponentElements = (scope, selector) => {
  const elements = scope.querySelectorAll(selector)
  if (!elements.length) {
    return []
  }

  return Array.from(elements)
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
const initializeComponent = (scope, selector, ComponentClass) => {
  if (!(ComponentClass.prototype instanceof Component)) {
    throw new Error(
      'Components can only be initialized when they inherit the basecomponent',
    )
  }

  const elements = typeof(selector) === 'function' ? selector(scope) : getComponentElements(scope, selector)
  if (!elements.length) {
    return []
  }

  return elements
    .filter((el) => !el.getAttribute(componentInitializedAttrName(ComponentClass.name)))
    .map((el) => new ComponentClass(el))
}

export {
  Component,
  initializeComponent,
  initializeRegisteredComponents,
  getComponentElements,
  registerComponent,
}
