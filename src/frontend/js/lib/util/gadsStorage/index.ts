import { AppStorage } from "./lib/AppStorage";

/**
 * GADS Storage instance - this is a singleton
 */
const gadsStorage = AppStorage.CreateStorageInstance();

export default gadsStorage;
