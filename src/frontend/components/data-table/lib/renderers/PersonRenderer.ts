import { Renderer } from 'js/lib/util/types';
import { encodeHTMLEntities } from 'util/common';

/**
 * Renderer for person data type.
 */
export class PersonRenderer implements Renderer {
    /**
     * Constructor for PersonRenderer.
     * @param {*} data The data to render.
     */
    constructor(private readonly data: any) {
    }

    /** @inheritdoc */
    render(): string {
        let strHTML = '';
        const data = this.data;

        if (!data.values.length) {
            return strHTML;
        }

        data.values.forEach((value) => {
            if (value.details.length) {
                let thisHTML = '<div>';
                value.details.forEach((detail) => {
                    const strDecodedValue = encodeHTMLEntities(detail.value);
                    if (detail.type === 'email') {
                        thisHTML += `<p>E-mail: <a href="mailto:${strDecodedValue}">${strDecodedValue}</a></p>`;
                    } else {
                        thisHTML += `<p>${encodeHTMLEntities(detail.definition)}: ${strDecodedValue}</p>`;
                    }
                });
                thisHTML += '</div>';
                strHTML += (
                    `<div class="position-relative">
            <button class="btn btn-small btn-inverted btn-info trigger" aria-expanded="false" type="button">
              ${encodeHTMLEntities(value.text)}
              <span class="invisible">contact details</span>
            </button>
            <div class="person contact-details expandable popover card card--secundary">
              ${thisHTML}
            </div>
          </div>`
                );
            }
        });

        return strHTML;
    }
}
