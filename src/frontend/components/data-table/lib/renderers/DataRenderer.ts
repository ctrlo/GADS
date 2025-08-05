import { IdRenderer } from './IdRenderer';
import { PersonRenderer } from './PersonRenderer';
import { CurCommonRenderer } from './CurCommonRenderer';
import { FileRenderer } from './FileRenderer';
import { RagRenderer } from './RagRenderer';
import { DefaultRenderer } from './DefaultRenderer';
import { Renderer } from 'js/lib/util/types';

/**
 * Abstract class for creating data renderers.
 */
export default abstract class DataRenderer {
    /**
     * Constructor for DataRenderer.
     * Throws an error if an attempt is made to instantiate this class directly,
     */
    constructor() {
        if (this.constructor === DataRenderer) {
            throw new Error('DataRenderer is an abstract class and cannot be instantiated directly.');
        }
    }

    /**
     * Create a renderer instance based on the type of data provided.
     * @param {*} data The data to determine the renderer type.
     * @returns {DataRenderer} An instance of a renderer that can handle the given data type.
     */
    static create(data: any): Renderer {
        switch (data.type) {
            case 'id':
                return new IdRenderer(data);
            case 'person':
            case 'createdby':
                return new PersonRenderer(data);
            case 'curval':
            case 'autocur':
            case 'filval':
                return new CurCommonRenderer(data);
            case 'file':
                return new FileRenderer(data);
            case 'rag':
                return new RagRenderer(data);
            default:
                return new DefaultRenderer(data);
        }
    }
}

