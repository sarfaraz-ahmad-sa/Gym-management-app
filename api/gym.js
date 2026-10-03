import { database } from "../server/database.js";
import { migrate } from "../server/schema.js";
import { createService } from "../server/service.js";
let ready, service;
export default async function handler(req, res) {
  res.setHeader("Cache-Control", "no-store");
  res.setHeader("X-Content-Type-Options", "nosniff");
  const origin = req.headers.origin;
  const allowed = (process.env.ALLOWED_ORIGINS ?? "")
    .split(",")
    .map((x) => x.trim())
    .filter(Boolean);
  const ownOrigin = `https://${req.headers.host}`;
  if (origin && origin !== ownOrigin && !allowed.includes(origin))
    return res.status(403).json({ error: "This web origin is not allowed." });
  if (origin) {
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader("Vary", "Origin");
  }
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  if (req.method === "OPTIONS") return res.status(204).end();
  if (req.method !== "POST")
    return res.status(405).json({ error: "Use POST." });
  try {
    let body = req.body;
    if (typeof body === "string") body = JSON.parse(body);
    if (!body || typeof body !== "object" || Array.isArray(body))
      return res.status(400).json({ error: "Invalid request." });
    if (Buffer.byteLength(JSON.stringify(body)) > 3 * 1024 * 1024)
      return res
        .status(413)
        .json({ error: "Request is too large. Maximum restore size is 3 MB." });
    const db = database();
    ready ??= migrate(db).catch((e) => {
      ready = undefined;
      throw e;
    });
    await ready;
    service ??= createService(db);
    const token = req.headers.authorization?.replace(/^Bearer /, "");
    // Vercel sets x-forwarded-for; local dev supplies socket address.
    const ip = String(
      req.headers["x-forwarded-for"] ?? req.socket?.remoteAddress ?? "unknown",
    )
      .split(",")[0]
      .trim();
    const result = await service(body, token, ip);
    return res.status(200).json(result);
  } catch (e) {
    let status = e.status ?? 500,
      message = e.status
        ? e.message
        : "The cloud request failed. Please retry.";
    if (e.code?.includes("CONSTRAINT")) {
      status = 409;
      message =
        "This record is duplicate or has linked history. Check the entry or archive the member.";
    }
    if (e instanceof SyntaxError) {
      status = 400;
      message = "Invalid JSON request.";
    }
    if (status === 500) console.error("FitGuide API error:", e.code ?? e.name);
    return res.status(status).json({ error: message });
  }
}
