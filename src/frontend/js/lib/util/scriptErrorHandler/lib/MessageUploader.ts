import { Uploader } from "util/upload/UploadControl";

export const uploadMessage = async (message: string) => {
    const body = {
        description: message,
        url: window.location.href
    };
    const uploader = new Uploader('/api/script_error', 'POST');
    const messageUploader = new MessageUploader(uploader);
    return await messageUploader.uploadMessage(body.description);
};

export class MessageUploader {
    constructor(private uploader: Uploader) {
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
