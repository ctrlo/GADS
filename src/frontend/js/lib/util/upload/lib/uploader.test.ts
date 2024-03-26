import {Uploader} from './uploader';

describe('Uploader', () => {
    it('should upload data async', async () => {
        const url = 'http://localhost:3000/upload';
        const data = new FormData();
        data.append('file', new Blob(['hello world'], {type: 'text/plain'}));
        const uploader = new Uploader<string>(url);
        uploader.onProgress((size, total) => {
            expect(size).toBeLessThan(total);
            expect(size).toEqual(10);
            expect(total).toEqual(100);
        });
        const result = await uploader.upload(data);
        expect(result).toEqual({status: 'success'});
    });

    it('should upload data using a promise', () => {
        const url = 'http://localhost:3000/upload';
        const data = new FormData();
        data.append('file', new Blob(['hello world'], {type: 'text/plain'}));
        const uploader = new Uploader<string>(url);
        uploader.upload(data).then(result => {
            expect(result).toEqual({status: 'success'});
        });
    });
});
