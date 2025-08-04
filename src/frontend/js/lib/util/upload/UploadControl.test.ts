import { describe, it, expect } from '@jest/globals';
import { Uploader, XmlHttpRequestLike } from './UploadControl';
import { initGlobals, MockXhr } from 'testing/globals.definitions';

describe('UploadControl', () => {
    let mockXhr: XmlHttpRequestLike | null;
    let oldXMLHttpRequest: XMLHttpRequest;

    beforeEach(() => {
        initGlobals();

        mockXhr = new MockXhr();
        oldXMLHttpRequest = <any>window.XMLHttpRequest;
        window.XMLHttpRequest = <any>(jest.fn(() => mockXhr));
    });

    afterEach(() => {
        window.XMLHttpRequest = <any>oldXMLHttpRequest;
        mockXhr = null;
    });

    it('ensure mocks are correct', async () => {
        const request = new XMLHttpRequest();
        expect(request).toBeDefined();
        expect(request.status).toBe(200);
        expect(request.readyState).toBe(4);
        expect(request.responseText).toBe(JSON.stringify({ error: 0 }));
    });

    it('should upload FormData using XMLHttpRequest', async () => {
        const localMock = mockXhr!;
        const { open, send } = localMock;
        const url = 'http://localhost';
        const method = 'POST';
        const data = new FormData();
        data.append('key', 'value');
        const uploader = new Uploader(url, method);
        const promise = uploader.upload(data);
        setTimeout(localMock.onreadystatechange!, 1000);
        const result = await promise;
        expect(open).toHaveBeenCalledWith(method, url);
        expect(send).toHaveBeenCalledWith(data);
        expect(result).toEqual({ error: 0 });
    });

    it('should upload object using XMLHttpRequest', async () => {
        const localMock = mockXhr!;
        const { open, send } = localMock;
        const url = 'http://localhost';
        const method = 'POST';
        const data = { key: 'value' };
        const uploader = new Uploader(url, method);
        const promise = uploader.upload(data);
        setTimeout(localMock.onreadystatechange!, 1000);
        const result = await promise;
        expect(open).toHaveBeenCalledWith(method, url);
        expect(send).toHaveBeenCalledWith(JSON.stringify(data));
        expect(result).toEqual({ error: 0 });
    });

    it('should use a progress callback', async () => {
        expect.assertions(2);
        const localMock = mockXhr!;
        const url = 'http://localhost';
        const method = 'POST';
        const data = { key: 'value' };
        const uploader = new Uploader(url, method);
        uploader.onProgress((loaded, total) => {
            expect(loaded).toBe(1);
            expect(total).toBe(2);
        });
        const promise = uploader.upload(data);
        const ev: ProgressEvent = {
            loaded: 1,
            total: 2,
            lengthComputable: true
        } as any;
        setTimeout(() => {
            if (localMock.upload?.onprogress)
                localMock.upload?.onprogress?.(ev);
        }, 500);
        setTimeout(localMock.onreadystatechange!, 1500);
        await promise;
    });

    it('should reject on error', async () => {
        const localMock = mockXhr!;
        const url = 'http://localhost';
        const method = 'POST';
        const data = { key: 'value' };
        const uploader = new Uploader(url, method);
        const promise = uploader.upload(data);
        localMock.status = 500;
        setTimeout(localMock.onreadystatechange!, 1000);
        try {
            await promise;
            // Should not reach this point - so we fail the test by default!
            expect(true).toBe(false);
        } catch (e) {
            expect(e).toBe(localMock.responseText);
        }
    });
});
