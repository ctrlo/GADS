/**
 * Interface for rendering data in a specific format.
 */
export interface Renderer {
    /**
     * Render the data in a specific format.
     * @returns {string} The rendered output as a string.
     */
    render(): string;
}
