import { Uploader } from 'util/upload/UploadControl';

/**
 * Upload a message to the server. It creates an instance of MessageUploader with a new Uploader and calls the uploadMessage method.
 * @param message The message content to upload
 */
export const uploadMessage = async (message: string) => {
    const body = {
        description: message,
        url: window.location.href
    };
    const uploader = new Uploader('/api/script_error', 'POST');
    const messageUploader = new MessageUploader(uploader);
    return await messageUploader.uploadMessage(body.description);
};

/**
 * Class to upload messages to the server. It takes an instance of Uploader to handle the actual upload process.
 */
export class MessageUploader {
    /**
     * Create an instance of MessageUploader.
     * @param uploader The uploader to use when uploading messages
     */
    constructor(private uploader: Uploader) {
    }

    /**
     * Upload a message to the server. It constructs the request body with the message description,
     * current URL, and CSRF token, then uses the uploader to send the data. If the upload fails, it logs an error to the console.
     * @param description The message content to be uploaded
     */
    async uploadMessage(description: string): Promise<void> {
        const csrf_token = document.body.dataset.csrf;
        const body = {
            description,
            url: window.location.href,
            csrf_token
        };
        try {
            return await this.uploader.upload(body);
        } catch (err) {
            console.error('Failed to upload message:', err);
        }
    }
}
