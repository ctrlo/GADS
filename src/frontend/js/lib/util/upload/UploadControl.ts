import { fromJson } from 'util/common';

/**
 * Type to represent a function that is called when the upload progress changes
 * @param loaded The number of bytes that have been uploaded
 * @param total The total number of bytes to upload
 */
type ProgressFunction = (loaded: number, total: number) => void;

/**
 * Type to represent the HTTP request methods that can be used for uploading data
 */
type RequestMethod = 'PUT' | 'POST' | 'GET' | 'DELETE' | 'PATCH';

/**
 * Type to represent an object similar to an XMLHttpRequest object
 */
type XmlHttpRequestLike = {
    open: (method: string, url: string) => void,
    onabort?: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null,
    onerror?: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null,
    onprogress?: ((e: ProgressEvent) => void) | null,
    onreadystatechange: ((this: XMLHttpRequest, ev: Event) => any) | null,
    send: (data?: Document | XMLHttpRequestBodyInit | null | undefined) => void,
    setRequestHeader: (header: string, value: string) => void,
    readyState: number,
    status: number,
    responseText: string,
    upload?: {
        onprogress?: ((e: ProgressEvent) => void) | null
    };
};

/**
 * Upload data to a server endpoint
 * @template T The type of the response data
 * @param { string | URL } url The endpoint to upload to
 * @param {FormData | object} data The form data or object to upload
 * @param { RequestMethod } method The method to use, either POST, PUT, or GET
 * @param { ProgressFunction } onProgress A callback that is called when the upload progress changes
 * @returns { Promise<T> } The JSON response from the server
 */
async function upload<T = unknown>(url: string | URL, data?: FormData | object, method: RequestMethod = 'POST', onProgress: ProgressFunction = () => { }, headers?: Record<string, string>): Promise<T> {
    const uploader = new Uploader(url, method);
    uploader.onProgress(onProgress);
    return uploader.upload(data, headers);
}

/**
 * Helper class to upload form data to a server endpoint
 * @todo The API class could be used within the Dashboard component rather than this class - we could also use this as a singleton
 */
class Uploader {
    private onProgressCallback?: ProgressFunction;

    /**
     * Create a new Uploader instance
     * @param {string} url The endpoint to upload to
     * @param {RequestMethod} method The method to use, either POST, PUT, or GET
     */
    constructor(private readonly url: string | URL, private readonly method: RequestMethod) {
    }

    /**
     * Set a callback that is called when the upload progress changes
     * @param {ProgressFunction} callback A callback that is called when the upload progress changes
     */
    onProgress(callback: ProgressFunction) {
        this.onProgressCallback = callback;
    }

    /**
     * Upload form data to a server endpoint
     * @template T The type of the response data
     * @param { FormData | object } data The form data or JSON object to upload
     * @returns { Promise<T> } A promise that resolves to the JSON response from the server
     */
    async upload<T>(data?: FormData | object, headers?: Record<string, string>): Promise<T> {
        return new Promise((resolve, reject) => {
            const request: XmlHttpRequestLike & XMLHttpRequest = new XMLHttpRequest();
            for(const [key, value] of Object.entries(headers || {})) {
                request.setRequestHeader(key, value);
            }
            request.open(this.method, this.url.toString());
            request.onabort = () => reject('aborted');
            request.onerror = () => reject('error');
            request.upload.onprogress = (e: ProgressEvent) => {
                if(!e.lengthComputable) this.onProgressCallback?.(e.loaded, 0);
                this.onProgressCallback?.(e.loaded, e.total);
            };
            request.onreadystatechange = () => {
                if (request.readyState === 4) {
                    if (request.status === 200) {
                        resolve(fromJson(request.responseText));
                    } else {
                        reject(request.responseText);
                    }
                }
            };

            if (data instanceof FormData) {
                request.send(data);
            } else {
                request.setRequestHeader('Content-Type', 'application/json');
                request.send(JSON.stringify(data));
            }
        });
    }
}

export { upload, Uploader, XmlHttpRequestLike };
