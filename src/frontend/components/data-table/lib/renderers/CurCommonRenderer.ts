import { Renderer } from 'js/lib/util/types';
import DataRenderer from './DataRenderer';
import { MoreLessRenderer } from './MoreLessRenderer';

/**
 * Renderer for curval data types.
 */
export class CurCommonRenderer extends MoreLessRenderer implements Renderer {
    /**
     * Constructor for CurCommonRenderer.
     * @param {*} data The data to render.
     */
    constructor(private readonly data: any) {
        super();
    }

    /** @inheritdoc */
    render(): string {
        const data = this.data;
        let strHTML = '';

        if (data.values.length === 0) {
            return strHTML;
        }

        strHTML = this.renderCurCommonTable(data);
        return this.renderMoreLess(strHTML, data.name);
    }

    /**
     * Render a curval table
     * @param {*} data The data to render
     * @returns {string} The rendered HTML string for the curval table
     */
    private renderCurCommonTable(data: any): string {
        let strHTML = '';

        if (data.values.length === 0) {
            return strHTML;
        }
        if (data.values[0].fields.length === 0) {
            // No columns visible to user
            return strHTML;
        }

        strHTML += '<table class="table-curcommon">';

        data.values.forEach((row) => {
            strHTML += `<tr role="button" tabindex="0" class="link record-popup" data-record-id="${row.record_id}"`;
            if (row.version_id) {
                strHTML += `data-version-id="${row.version_id}"`;
            }
            strHTML += '>';
            if (row.status) {
                strHTML += `<td><em>${row.status}:</em></td>`;
            }

            row.fields.forEach((field: any) => {
                strHTML += `<td class="${field.type}">${DataRenderer.create(field).render()}</td>`;
            });
            strHTML += '</tr>';
        });

        strHTML += '</table>';

        if (data.limit_rows && data.values.length >= data.limit_rows) {
            strHTML +=
                `<p><em>(showing maximum ${data.limit_rows} rows.
          <a href="/${data.parent_layout_identifier}/data?curval_record_id=${data.curval_record_id}&curval_layout_id=${data.column_id}">view all</a>)</em>
        </p>`;
        }

        return strHTML;
    }
}
