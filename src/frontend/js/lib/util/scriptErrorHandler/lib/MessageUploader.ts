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
    const messageUploader = MessageUploader.instance;
    return await messageUploader.uploadMessage(body.description);
};

/**
 * MessageUploader is a singleton class that handles the uploading of messages to the server. It uses an instance of Uploader to perform the actual upload.
 */
class MessageUploader {
    private static _instance: MessageUploader;

    /**
     * Create a new instance of MessageUploader with the provided Uploader.
     */
    constructor(private uploader: Uploader) {
    }

    /**
     * Get the singleton instance of MessageUploader. If it doesn't exist, create a new instance with a new Uploader.
     */
    static get instance(): MessageUploader {
        if (!this._instance) {
            this._instance = new MessageUploader(new Uploader('/api/script_error', 'POST'));
        }
        return this._instance;
    }

    /**
     * Uploads a message to the server.
     * It constructs the request body with the provided description, current URL, and CSRF token, then calls the upload method of the Uploader instance.
     * If the upload fails, it logs an error to the console.
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
