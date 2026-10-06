declare module "logging" {
    export interface Logging {
        log(...message: unknown[]): void;
        info(...message: unknown[]): void;
        warn(...message: unknown[]): void;
        error(...message: unknown[]): void;
        formatMessage(type: string, ...message: unknown[]): string;
    }

    export const logging: Logging;
}
