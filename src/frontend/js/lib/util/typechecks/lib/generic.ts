export const isDefined = <T> (value: unknown): value is NonNullable<T> => value !== undefined && value !== null;
