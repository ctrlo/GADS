import { describe, it, expect, beforeEach } from '@jest/globals';
import StorageProvider from './storageProvider';

describe('StorageProvider', () => {
    beforeEach(() => {
        localStorage.clear();
    });

    it('should add a key-value pair', async () => {
        const storage = new StorageProvider('test', localStorage);
        await expect(storage.setItem('key', 'value')).resolves.toBeUndefined();
        expect(localStorage.getItem('test')).toBe('{"key":"value"}');
    });

    it('should get a value by key', async () => {
        const storage = new StorageProvider('test', localStorage);
        await expect(storage.setItem('key', 'value')).resolves.toBeUndefined();
        await expect(storage.getItem('key')).resolves.toBe('value');
    });

    it('should return undefined if key does not exist', async () => {
        const storage = new StorageProvider('test', localStorage);
        await expect(storage.getItem('key')).resolves.toBe(undefined);
    });

    it('should return all key-value pairs', async () => {
        const storage = new StorageProvider('test', localStorage);
        await expect(storage.setItem('key', 'value')).resolves.toBeUndefined();
        await expect(storage.getAll()).resolves.toEqual({ key: 'value' });
    });

    it('should return an empty object if no key-value pairs exist', async () => {
        const storage = new StorageProvider('test', localStorage);
        await expect(storage.getAll()).resolves.toEqual({});
    });

    it('should get different values for different instances', async () => {
        const storage1 = new StorageProvider('test1', localStorage);
        const storage2 = new StorageProvider('test2', localStorage);
        await expect(storage1.setItem('key', 'value1')).resolves.toBeUndefined();
        await expect(storage2.setItem('key', 'value2')).resolves.toBeUndefined();
        await expect(storage1.getItem('key')).resolves.toBe('value1');
        await expect(storage2.getItem('key')).resolves.toBe('value2');
    });

    it('should update a key-value pair', async () => {
        const storage = new StorageProvider('test', localStorage);
        await expect(storage.setItem('key', 'value')).resolves.toBeUndefined();
        await expect(storage.getItem('key')).resolves.toBe('value');
        await expect(storage.setItem('key', 'new value')).resolves.toBeUndefined();
        await expect(storage.getItem('key')).resolves.toBe('new value');
    });
    
    it('should remove a key-value pair', async () => {
        const storage = new StorageProvider('test', localStorage);
        await expect(storage.setItem('key', 'value')).resolves.toBeUndefined();
        await expect(storage.getItem('key')).resolves.toBe('value');
        await expect(storage.removeItem('key')).resolves.toBeUndefined();
        await expect(storage.getItem('key')).resolves.toBe(undefined);
    });

    it('should set multipe key value pairs on the same instance', async () => {
        const storage = new StorageProvider('test', localStorage);
        await expect(storage.setItem('key1', 'value1')).resolves.toBeUndefined();
        await expect(storage.setItem('key2', 'value2')).resolves.toBeUndefined();
        await expect(storage.getAll()).resolves.toEqual({ key1: 'value1', key2: 'value2' });
    });
});
