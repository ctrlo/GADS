import gadsStorage from "util/gadsStorage";
import { AppStorage } from "util/gadsStorage/lib/AppStorage";
import { fromJson } from "util/common"

type StringMap = { [key: string]: string };

class StorageProvider {
    get provider() {return this.storage;}
    
    constructor(private readonly instance: string, private readonly storage:Storage | AppStorage = gadsStorage) {
    }

    async setItem(key:string, value: string) {
        let item = await this.storage.getItem(this.instance);
        if(!item) item = '{}';
        const map: StringMap = fromJson(item);
        map[key] = value;
        await this.storage.setItem(this.instance, JSON.stringify(map));
    }

    async getItem(key: string): Promise<string| undefined> {
        const item = await this.storage.getItem(this.instance);
        if(!item) return undefined;
        const map: StringMap = fromJson(item);
        return map[key] || undefined;
    }

    async getAll(): Promise<StringMap> {
        const item = await this.storage.getItem(this.instance);
        if(!item) return {};
        return fromJson(item);
    }

    async clear() {
        this.storage.removeItem(this.instance);
    }

    async removeItem(key: string) {
        const item = await this.storage.getItem(this.instance);
        if(!item) return;
        const map: StringMap = fromJson(item);
        delete map[key];
        await this.storage.setItem(this.instance, JSON.stringify(map));
    }
}

export default StorageProvider;