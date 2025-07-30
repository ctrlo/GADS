import { Renderer } from 'js/lib/util/types';

/**
 * Renderer for ID data type.
 */
export class IdRenderer implements Renderer {
    /**
     * Constructor for IdRenderer.
     * @param {*} data The data object containing ID information.
     */
    constructor(private readonly data: any) {
    }

    /** @inheritdoc */
    render(): string {
        const data = this.data;
        let retval = '';
        const id = data.values[0];
        if (!id) return retval;
        if (data.parent_id) {
            retval = `<span title="Child record with parent record ${this.data.parent_id}">${data.parent_id} &#8594;</span> `;
        }
        return retval + `<a href="${data.base_url}/${id}">${id}</a>`;
    }
}
