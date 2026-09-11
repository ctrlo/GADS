declare module "component" {
    /**
     * Default component class.
     * Components should inherit this class.
     */
    abstract class Component {
        /**
         * Whether a component can be reinitialized on an element. For legacy
         * reasons, the default is not to be and initialization will only be run
         * once. For components that set this to true, they must cleanly handle
         * such a reinitialization (returning the object but not resetting up HTML
         * elements etc)
         * @returns True if the component can be reinitialized, false otherwise
         */
        static get allowReinitialization(): boolean;

        /**
         * The HTML element the component is associated with.
         */
        readonly element: HTMLElement;

        /**
         * Create a new component instance.
         * @param element The element to initialize the component on
         * @throws If the element is not an HTMLElement
         */
        constructor(element: HTMLElement);
    }

    /**
     * Register a component that can be initialized
     * @param componentInitializer Function that will be called when component initializes
     */
    const registerComponent: (componentInitializer: Function) => void;

    /**
     * Initialize all registered components in the defined scope
     * @param scope The scope to initialize the components in (either JQuery elements or DOM).
     */
    const initializeRegisteredComponents: (scope: HTMLElement | JQuery<HTMLElement>) => void;

    /**
     * Get an Array of elements matching `selector` within `scope`
     * @param scope The scope to select elements
     * @param selector The selector to select elements
     * @returns An array of elements
     */
    const getComponentElements: (scope: HTMLElement, selector: string) => HTMLElement[];

    /**
     * Initialize component `Component` on all elements matching `selector` within `scope`
     * Will only initialize elements that have not been initialized.
     * @param scope The scope to initialize the objects on
     * @param selector The selector to select elements
     * @param componentClass The Component class to initialize
     * @returns An array of initialized components
     */
    const initializeComponent: <T extends Component>(scope: HTMLElement, selector: string | Function, componentClass: T) => T[];

}
