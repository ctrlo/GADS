import { Renderer } from 'js/lib/util/types';

/**
 * Renderer for RAG data type.
 */
export class RagRenderer implements Renderer {
    /**
     * Constructor for RagRenderer.
     * @param {*} data The data to render.
     */
    constructor(private readonly data: any) {
    }

    /** @inheritdoc */
    render(): string {
        const data = this.data;
        let strRagType = '';
        const arrRagTypes = {
            a_grey: 'undefined',
            b_red: 'danger',
            b_attention: 'attention',
            c_amber: 'warning',
            c_yellow: 'advisory',
            d_green: 'success',
            d_blue: 'complete',
            e_purple: 'unexpected'
        };

        if (data.values.length) {
            const value = data.values[0]; // There's always only one rag
            strRagType = arrRagTypes[value] || 'blank';
        } else {
            strRagType = 'blank';
        }

        const text = $('#rag_' + strRagType + '_meaning').text();

        return `<span class="rag rag--${strRagType}" title="${text}" aria-labelledby="rag_${strRagType}_meaning"><span>✗</span></span>`;
    }
}
