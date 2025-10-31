import { isDefined } from "./generic";

export const isNumber = (value: unknown): value is number => isDefined(value) && (typeof value === "number" || value instanceof Number);
