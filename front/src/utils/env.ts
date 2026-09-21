export function getEnv(key: string): string {
  const value = import.meta.env[key] as string | undefined;
  if (!value) throw new Error(`Missing environment variable: ${key}`);
  return value;
}
