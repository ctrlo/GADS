import { Uploader } from "util/upload/UploadControl";

export const uploadMessage = async (message: string) => {
    const body = {
        description: message,
        url: window.location.href
    };
    const messageUploader = MessageUploader.instance;
    return await messageUploader.uploadMessage(body.description);
};

class MessageUploader {
    private static _instance: MessageUploader;

    constructor(private uploader: Uploader) {
    }

    static get instance(): MessageUploader {
        if (!this._instance) {
            this._instance = new MessageUploader(new Uploader('/api/script_error', 'POST'));
        }
        return this._instance;
    }

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
            console.error("Failed to upload message:", err);
        }
    }
}
