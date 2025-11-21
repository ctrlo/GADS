import { describe, it, expect, jest } from '@jest/globals';
import { MessageUploader } from './MessageUploader';

describe('MessageUploader', () => {
    class MockUploader {
        upload = jest.fn();
    }

    it('should upload messages correctly', async () => {
        const uploader = new MockUploader();
        const messageUploader = new MessageUploader(uploader);

        const messages = { id: 1, content: 'Test message 1' };

        await messageUploader.uploadMessage(JSON.stringify(messages));

        expect(uploader.upload).toHaveBeenCalledTimes(1);
        expect(uploader.upload).toHaveBeenCalledWith({
            description: JSON.stringify(messages),
            method: 'N/A',
            url: 'http://localhost/'
        });
    });
});