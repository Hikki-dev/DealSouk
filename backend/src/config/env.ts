export function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function requireProductionEnv(names: string[]): void {
  if (process.env.NODE_ENV !== "production") return;
  for (const name of names) {
    requireEnv(name);
  }
}
