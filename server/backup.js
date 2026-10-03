import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { gzipSync } from "node:zlib";
import { database } from "./database.js";
import { tables } from "./service.js";
const db = database();
try {
  const directory = process.env.BACKUP_DIRECTORY ?? "backups";
  await mkdir(directory, { recursive: true });
  const workspaces = (await db.execute("SELECT id,name FROM workspaces")).rows;
  for (const w of workspaces) {
    const tx = await db.transaction("read");
    let data = {};
    try {
      for (const table of [...tables, "settings"])
        data[table] = (
          await tx.execute({
            sql: `SELECT * FROM ${table} WHERE workspace_id=?`,
            args: [w.id],
          })
        ).rows.map((r) =>
          Object.fromEntries(
            Object.entries(r).filter(([k]) => k !== "workspace_id"),
          ),
        );
      await tx.commit();
    } catch (e) {
      await tx.rollback();
      throw e;
    } finally {
      tx.close();
    }
    const backup = {
      format: "fitguide-backup",
      version: 1,
      workspace_name: w.name,
      exported_at: new Date().toISOString(),
      tables: data,
    };
    await writeFile(
      join(
        directory,
        `${w.id}-${new Date().toISOString().slice(0, 10)}.json.gz`,
      ),
      gzipSync(JSON.stringify(backup)),
      { mode: 0o600 },
    );
  }
  console.log(
    `Backed up ${workspaces.length} workspaces. Credentials and sessions excluded.`,
  );
} finally {
  db.close();
}
