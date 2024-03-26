import { fromJson } from "util/common";

/**
 * Upload form data to a server endpoint
 * @param url The endpoint to upload to
 * @param data The form data to upload
 * @param method The method to use, either POST or PUT
 * @returns A promise that resolves to the JSON response from the server
 */
function upload<T>(url: string, data: FormData, method: 'POST' | 'PUT' = 'POST'): Promise<T> {
    const uploader = new Uploader<T>(url, method);
    return uploader.upload(data);
}

/**
 * Helper class to upload form data to a server endpoint
 */
class Uploader<T> {
    private onProgressCallback:(size:number, total:number)=>void;

    /**
     * Set a callback that is called when the upload progress changes
     * @param callback A callback that is called when the upload progress changes
     */
    onProgress(callback: (size:number, total:number)=>void) {
        this.onProgressCallback = callback;
    }

    /**
     * Create a new uploader
     * @param url The endpoint to upload to
     * @param method The method to use, either POST or PUT
     */
    constructor(private readonly url: string, private readonly method: 'POST' | 'PUT' = 'POST') {
    }

    /**
     * Upload form data to a server endpoint
     * @param data The form data to upload
     * @returns A promise that resolves to the JSON response from the server
     */
    upload(data: FormData): Promise<T> {
        return window.test ? this.mockUpload(data) : this.liveUpload(data);
    }

    private mockUpload(data: FormData): Promise<T> {
        return new Promise((resolve, reject) => {
            setTimeout(() => {
                this.onProgressCallback && this.onProgressCallback(10,100);
            }, 500);
            setTimeout(() => {
                resolve(fromJson('{"status":"success"}'));
            }, 1000);
        });
    }

    private liveUpload(data: FormData): Promise<T> {
        const request = new XMLHttpRequest();
        request.open(this.method, this.url);
        request.send(data);
        return new Promise((resolve, reject) => {
            request.onabort = () => reject('aborted');
            request.onerror = () => reject('error');
            request.onprogress = (e) => { 
                this.onProgress && this.onProgressCallback(e.loaded, e.total);
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
        });
    }
}

export { upload, Uploader };
