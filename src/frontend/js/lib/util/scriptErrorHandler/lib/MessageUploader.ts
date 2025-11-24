import { Uploader } from "util/upload/UploadControl";

export const uploadMessage = async (message: string, method?: string) => {
    const body = {
        description: message,
        method: method || 'N/A',
        url: window.location.href
    };
    const token = document.body.dataset.csrf;
    const uploader = new Uploader('/api/script_error?csrf_token='+token, 'POST');
    const messageUploader = new MessageUploader(uploader);
    return await messageUploader.uploadMessage(body.description, body.method);
};

export class MessageUploader {
    constructor(private uploader: Uploader) {
    }

    async uploadMessage(description: string, method?: string): Promise<void> {
        method ||= 'N/A';
        const body = {
            description,
            method,
            url: window.location.href
        };
        try {
            return await this.uploader.upload(body);
        } catch (err) {
            console.error("Failed to upload message:", err);
        }
    }
}