import { database } from "./database.js";
import { migrate } from "./schema.js";
const db = database();
try {
  await migrate(db);
  console.log("FitGuide schema ready.");
} finally {
  db.close();
}
