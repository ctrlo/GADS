import { encodeHTMLEntities } from 'util/common';
import { MoreLessRenderer } from './MoreLessRenderer';
import { Renderer } from 'js/lib/util/types';

/**
 * Renderer for default data type.
 * This renderer is used when no specific renderer is defined for the data type.
 */
export class DefaultRenderer extends MoreLessRenderer implements Renderer {
    /**
     * Constructor for DefaultRenderer.
     * @param {*} data The data to render.
     */
    constructor(private readonly data: any) {
        super();
    }

    /** @inheritdoc */
    render(): string {
        const data = this.data;
        let strHTML = '';

        if (!data.values || !data.values.length) {
            return strHTML;
        }

        data.values.forEach((value, i) => {
            strHTML += encodeHTMLEntities(value);
            strHTML += (data.values.length > (i + 1)) ? ', ' : '';
        });

        return this.renderMoreLess(strHTML, data.name);
    }
}
