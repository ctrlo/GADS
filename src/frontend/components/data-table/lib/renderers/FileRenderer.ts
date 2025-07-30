import { Renderer } from 'js/lib/util/types';
import { encodeHTMLEntities } from 'util/common';

/**
 * Renderer for file data type.
 */
export class FileRenderer implements Renderer {
    /**
     * Constructor for FileRenderer.
     * @param {*} data The data to render.
     */
    constructor(private readonly data: any) {
    }

    /** @inheritdoc */
    render(): string {
        const data = this.data;
        let strHTML = '';

        if (!data.values.length) {
            return strHTML;
        }

        data.values.forEach((file: { id: string | number; name: string; mimetype: string; }) => {
            strHTML += `<a href="/file/${file.id}">`;
            if (file.mimetype.match('^image/')) {
                strHTML += `<img class="autosize" src="/file/${file.id}"></img>`;
            } else {
                strHTML += `${encodeHTMLEntities(file.name)}<br>`;
            }
            strHTML += '</a>';
        });

        return strHTML;
    }
}
