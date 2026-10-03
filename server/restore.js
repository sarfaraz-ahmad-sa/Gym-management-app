import { readFile } from "node:fs/promises";
import { createInterface } from "node:readline/promises";
import { Writable } from "node:stream";
import { stdin, stdout } from "node:process";
import { gunzipSync } from "node:zlib";
import { database } from "./database.js";
import { createService } from "./service.js";
const { RESTORE_USERNAME, RESTORE_WORKSPACE_ID, RESTORE_FILE } = process.env;
if (!RESTORE_USERNAME || !RESTORE_WORKSPACE_ID || !RESTORE_FILE)
  throw new Error(
    "Set RESTORE_USERNAME, RESTORE_WORKSPACE_ID and RESTORE_FILE.",
  );
if (!stdin.isTTY)
  throw new Error("Run this script in an interactive terminal.");
let muted = false;
const output = new Writable({
  write(chunk, _encoding, callback) {
    if (!muted) stdout.write(chunk);
    callback();
  },
});
const prompt = createInterface({ input: stdin, output, terminal: true });
const db = database(),
  call = createService(db);
try {
  stdout.write("Owner password: ");
  muted = true;
  const password = await prompt.question("");
  muted = false;
  stdout.write("\n");
  const session = await call(
    { action: "login", username: RESTORE_USERNAME, password },
    null,
    "trusted-restore",
  );
  if (!session.workspaces.some((w) => w.id === RESTORE_WORKSPACE_ID))
    throw new Error("Owner does not have access to this workspace.");
  const confirm = await prompt.question(
    `This replaces records in ${RESTORE_WORKSPACE_ID}. Type that exact workspace ID: `,
  );
  if (confirm !== RESTORE_WORKSPACE_ID) throw new Error("Restore cancelled.");
  const bytes = await readFile(RESTORE_FILE);
  const json = RESTORE_FILE.endsWith(".gz")
    ? gunzipSync(bytes).toString()
    : bytes.toString();
  await call(
    {
      action: "restore",
      workspaceId: RESTORE_WORKSPACE_ID,
      backup: JSON.parse(json),
    },
    session.token,
  );
  await call({ action: "logout" }, session.token);
  console.log("Workspace restored successfully.");
} finally {
  prompt.close();
  db.close();
}
