import { createClient } from "@libsql/client";
let client;
export function database() {
  const url = process.env.TURSO_DATABASE_URL;
  if (!url)
    throw Object.assign(
      new Error(
        "Cloud database is not configured. Add TURSO_DATABASE_URL and TURSO_AUTH_TOKEN in Vercel settings.",
      ),
      { status: 503 },
    );
  if (!url.startsWith("file:") && !process.env.TURSO_AUTH_TOKEN)
    throw Object.assign(new Error("Cloud database credentials are missing."), {
      status: 503,
    });
  return (client ??= createClient({
    url,
    authToken: process.env.TURSO_AUTH_TOKEN,
  }));
}
