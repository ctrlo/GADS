/**
 * Abstract class for more-less rendering functionality.
 * This class provides a method to render a more-less component if the HTML string exceeds a certain threshold.
 */
export abstract class MoreLessRenderer {
    private readonly MORE_LESS_TRESHOLD = 50;

    /**
     * Render a more-less component if the HTML string exceeds the threshold
     * @param {string} strHTML The HTML string to render
     * @param {string} strColumnName The name of the column to render
     * @returns {string} The rendered HTML string with more-less component if applicable
     */
    protected renderMoreLess(strHTML: string, strColumnName: string): string {
        if (strHTML.toString().length > this.MORE_LESS_TRESHOLD) {
            return (
                `<div class="more-less" data-column="${strColumnName}">
                    ${strHTML}
                </div>`
            );
        }
        return strHTML;
    }
}
