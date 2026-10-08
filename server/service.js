import {
  randomBytes,
  randomUUID,
  createHash,
  scrypt as scryptCallback,
  timingSafeEqual,
} from "node:crypto";
import { promisify } from "node:util";
import { addCalendarDays, calendarDate, defaultTimeZone, validTimeZone, workspaceTimeZone } from "./calendar.js";
const scrypt = promisify(scryptCallback);
export const tables = [
  "membership_plans",
  "trainers",
  "members",
  "fee_invoices",
  "attendance",
  "payments",
  "inventory_items",
  "workout_plans",
  "member_workout_assignments",
];
const fields = {
  membership_plans: [
    "name",
    "description",
    "price",
    "duration_days",
    "features",
  ],
  trainers: ["name", "phone", "email", "specialization", "hire_date", "status"],
  members: [
    "name",
    "phone",
    "email",
    "address",
    "join_date",
    "plan_id",
    "status",
    "trainer_id",
    "expiry_date",
    "goal",
  ],
  fee_invoices: [
    "member_id",
    "amount",
    "due_date",
    "period",
    "description",
    "status",
  ],
  attendance: ["member_id", "check_in", "check_out", "notes"],
  payments: [
    "member_id",
    "plan_id",
    "amount",
    "payment_date",
    "status",
    "payment_method",
    "transaction_id",
    "invoice_id",
    "renewal_applied",
  ],
  inventory_items: [
    "name",
    "category",
    "quantity",
    "condition",
    "purchase_price",
    "purchase_date",
    "notes",
  ],
  workout_plans: ["name", "description", "level", "duration_weeks"],
  member_workout_assignments: [
    "member_id",
    "workout_plan_id",
    "assigned_date",
    "status",
  ],
};
const required = {
  membership_plans: ["name", "price", "duration_days"],
  trainers: ["name", "phone"],
  members: ["name", "phone", "join_date", "status"],
  fee_invoices: ["member_id", "amount", "due_date", "status"],
  payments: ["member_id", "amount", "payment_date", "status"],
  inventory_items: ["name", "category", "quantity"],
  workout_plans: ["name", "duration_weeks"],
  attendance: ["member_id", "check_in"],
  member_workout_assignments: [
    "member_id",
    "workout_plan_id",
    "assigned_date",
    "status",
  ],
};
const refs = {
  member_id: "members",
  plan_id: "membership_plans",
  trainer_id: "trainers",
  workout_plan_id: "workout_plans",
  invoice_id: "fee_invoices",
};
const allowedSettings = new Set([
  "gym_name",
  "currency",
  "country_code",
  "timezone",
  "gym_logo",
  "gym_address",
  "gym_phone",
  "gym_email",
  "gym_hours",
  "message_tagline",
  "message_payment",
  "message_welcome",
  "message_renewal",
]);
export const hashToken = (t) => createHash("sha256").update(t).digest("hex");
const fail = (message, status = 400) => {
  throw Object.assign(new Error(message), { status });
};
const text = (v, label, max = 160) => {
  if (typeof v !== "string" || !v.trim() || v.length > max)
    fail(`Enter a valid ${label}.`);
  return v.trim();
};
const idNumber = (v) => {
  if (!Number.isSafeInteger(v) || v <= 0) fail("Invalid record ID.");
  return v;
};
const secureEqual = (a, b) => {
  const x = Buffer.from(a),
    y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
};
const passwordHash = async (password, salt) =>
  (
    await scrypt(password, salt, 64, {
      N: 16384,
      r: 8,
      p: 1,
      maxmem: 64 * 1024 * 1024,
    })
  ).toString("hex");
const checkPassword = (p) => {
  if (typeof p !== "string" || p.length < 8 || p.length > 256)
    fail("Use a password between 8 and 256 characters.");
};
const clean = (row) =>
  Object.fromEntries(Object.entries(row).filter(([k]) => k !== "workspace_id"));
async function transaction(db, fn) {
  const tx = await db.transaction("write");
  try {
    const result = await fn(tx);
    await tx.commit();
    return result;
  } catch (e) {
    await tx.rollback();
    throw e;
  } finally {
    tx.close();
  }
}
async function one(db, table, id, w) {
  idNumber(id);
  const r = await db.execute({
    sql: `SELECT * FROM ${table} WHERE id=? AND workspace_id=?`,
    args: [id, w],
  });
  if (!r.rows.length) fail("Record not found in this workspace.", 404);
  return r.rows[0];
}
async function setSettings(db, w, values) {
  if (!values || typeof values !== "object" || Array.isArray(values))
    fail("Invalid workspace settings.");
  for (const [key, value] of Object.entries(values)) {
    if (!allowedSettings.has(key) || typeof value !== "string")
      fail("Invalid setting.");
    if (key === "gym_logo" && value) {
      if (
        !/^data:image\/(png|jpeg|webp);base64,[A-Za-z0-9+/]+=*$/.test(value) ||
        value.length > 262144
      )
        fail("Choose a PNG, JPEG or WebP logo under 190 KB.");
      const bytes = Buffer.from(value.split(",")[1], "base64");
      if (
        !(
          bytes.subarray(0, 8).toString("hex") === "89504e470d0a1a0a" ||
          (bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255) ||
          (bytes.subarray(0, 4).toString() === "RIFF" &&
            bytes.subarray(8, 12).toString() === "WEBP")
        )
      )
        fail("Logo file content is invalid.");
    } else if (key !== "gym_logo" && value.length > 3000)
      fail("Setting is too long.");
    if (key === "gym_name") {
      text(value, "workspace name");
      await db.execute({
        sql: "UPDATE workspaces SET name=? WHERE id=?",
        args: [value.trim(), w],
      });
    }
    if (
      key === "currency" &&
      !["PKR", "USD", "AED", "GBP", "EUR", "INR", "SAR"].includes(value)
    )
      fail("Invalid currency.");
    if (key === "country_code" && !/^[1-9]\d{0,3}$/.test(value))
      fail("Invalid country code.");
    if (key === "timezone" && !validTimeZone(value))
      fail("Choose a valid IANA timezone, such as Asia/Karachi.");
    await db.execute({
      sql: "INSERT INTO settings(workspace_id,key,value) VALUES(?,?,?) ON CONFLICT(workspace_id,key) DO UPDATE SET value=excluded.value",
      args: [w, key, value],
    });
  }
}
async function insert(db, table, row, w) {
  const keys = Object.keys(row);
  const result = await db.execute({
    sql: `INSERT INTO ${table}(workspace_id,${keys.join(",")}) VALUES(${Array(
      keys.length + 1,
    )
      .fill("?")
      .join(",")})`,
    args: [w, ...Object.values(row)],
  });
  return Number(result.lastInsertRowid);
}
async function validate(
  db,
  table,
  row,
  w,
  id = null,
  records = null,
  phones = null,
) {
  if (!fields[table] || !row || typeof row !== "object" || Array.isArray(row))
    fail("Invalid record type.");
  for (const key of Object.keys(row)) {
    if (!fields[table].includes(key)) fail(`Unknown field: ${key}.`);
    const v = row[key];
    if (v == null) continue;
    if (typeof v !== "string" && typeof v !== "number")
      fail("Invalid field value.");
    if (typeof v === "string" && v.length > 6000)
      fail("Record text is too long.");
    if (
      typeof v === "number" &&
      !refs[key] &&
      ![
        "price",
        "amount",
        "purchase_price",
        "duration_days",
        "duration_weeks",
        "quantity",
        "join_date",
        "expiry_date",
        "due_date",
        "payment_date",
        "check_in",
        "check_out",
        "hire_date",
        "purchase_date",
        "assigned_date",
        "renewal_applied",
      ].includes(key)
    )
      fail("Text fields must contain text.");
    if (typeof v === "number" && (!Number.isFinite(v) || v < 0))
      fail("Numeric fields must be non-negative.");
    if (refs[key]) {
      if (records) {
        if (!records[refs[key]]?.has(v))
          fail("Backup contains an invalid linked record.");
      } else await one(db, refs[key], v, w);
    }
    if (
      [
        "duration_days",
        "duration_weeks",
        "quantity",
        "join_date",
        "expiry_date",
        "due_date",
        "payment_date",
        "check_in",
        "check_out",
        "hire_date",
        "purchase_date",
        "assigned_date",
      ].includes(key) &&
      (!Number.isSafeInteger(v) || v < 0)
    )
      fail(`Invalid ${key}.`);
  }
  for (const key of required[table])
    if (row[key] == null || row[key] === "") fail(`Missing ${key}.`);
  for (const key of ["price", "amount", "purchase_price"])
    if (row[key] != null && typeof row[key] !== "number")
      fail("Amounts must be numeric.");
  if (
    row.duration_days != null &&
    (row.duration_days < 1 || row.duration_days > 3650)
  )
    fail("Plan duration must be 1–3650 days.");
  if (
    row.duration_weeks != null &&
    (row.duration_weeks < 1 || row.duration_weeks > 520)
  )
    fail("Workout duration must be 1–520 weeks.");
  if (row.period != null && !/^\d{4}-\d{2}$/.test(row.period))
    fail("Use YYYY-MM for the fee month.");
  const statuses = {
    members: ["active", "inactive", "suspended"],
    trainers: ["active", "inactive"],
    payments: ["completed", "pending", "failed"],
    fee_invoices: ["unpaid", "void"],
    member_workout_assignments: ["active", "completed"],
  };
  if (
    row.status != null &&
    statuses[table] &&
    !statuses[table].includes(row.status)
  )
    fail("Invalid status.");
  if (table === "members") {
    if (row.expiry_date != null && row.expiry_date < row.join_date)
      fail("Membership cannot end before joining.");
    const phone = row.phone.replace(/\D/g, "");
    if (phone.length < 7 || phone.length > 15)
      fail("Enter a valid phone number.");
    // Normalization in SQL handles common formats without trusting client checks.
    const normalized =
      "replace(replace(replace(replace(replace(phone,' ',''),'-',''),'(',''),')',''),'+','')";
    if (phones) {
      if (phones.has(phone))
        fail("Backup contains duplicate member phone numbers.");
      phones.add(phone);
    } else {
      const duplicates = await db.execute({
        sql: `SELECT id FROM members WHERE workspace_id=? AND ${normalized}=? AND id!=?`,
        args: [w, phone, id ?? -1],
      });
      if (duplicates.rows.length)
        fail("A member with this phone number already exists.");
    }
  }
  if (table === "payments" && row.invoice_id != null) {
    const invoice = records
      ? records.fee_invoices.get(row.invoice_id)
      : await one(db, "fee_invoices", row.invoice_id, w);
    if (invoice.member_id !== row.member_id || invoice.status === "void")
      fail("Choose an active invoice for the selected member.");
  }
  if (row.renewal_applied != null && ![0, 1].includes(row.renewal_applied))
    fail("Invalid renewal history.");
  if (table === "fee_invoices" && id != null) {
    const original = await one(db, table, id, w);
    if (original.member_id !== row.member_id) {
      const linked = await db.execute({
        sql: "SELECT id FROM payments WHERE workspace_id=? AND invoice_id=? LIMIT 1",
        args: [w, id],
      });
      if (linked.rows.length) fail("An invoice with linked payments cannot change member.");
    }
  }
  if (table === "fee_invoices" && id != null && row.status === "void") {
    const paid = await db.execute({
      sql: "SELECT id FROM payments WHERE workspace_id=? AND invoice_id=? LIMIT 1",
      args: [w, id],
    });
    if (paid.rows.length)
      fail("An invoice with linked payments cannot be voided.");
  }
}
export function createService(db, env = process.env, { now = Date.now } = {}) {
  const session = async (account) => {
    const token = randomBytes(32).toString("base64url");
    await db.execute({
      sql: "INSERT INTO cloud_sessions(token_hash,account_id,expires_at) VALUES(?,?,?)",
      args: [hashToken(token), account.id, now() + 7 * 86400000],
    });
    return {
      token,
      ownerName: account.name,
      workspaces: (
        await db.execute({
          sql: "SELECT id,name FROM workspaces WHERE owner_id=? ORDER BY created_at",
          args: [account.id],
        })
      ).rows,
    };
  };
  const authenticate = async (token) => {
    if (typeof token !== "string" || token.length > 256)
      fail("Sign in to continue.", 401);
    const rows = await db.execute({
      sql: "SELECT a.id,a.name,a.username FROM accounts a JOIN cloud_sessions s ON s.account_id=a.id WHERE s.token_hash=? AND s.expires_at>?",
      args: [hashToken(token), now()],
    });
    if (!rows.rows.length)
      fail("Your session expired. Please sign in again.", 401);
    return rows.rows[0];
  };
  const throttle = async (ip, username) => {
    await transaction(db, async (tx) => {
      const attemptTime = now();
      await tx.execute({
        sql: "DELETE FROM auth_attempts WHERE window_start < ?",
        args: [attemptTime - 3600000],
      });
      for (const source of [`ip:${ip}`, `user:${username}`]) {
        const key = hashToken(source);
        const existing = (
          await tx.execute({
            sql: "SELECT * FROM auth_attempts WHERE key=?",
            args: [key],
          })
        ).rows[0];
        if (
          existing &&
          existing.window_start > attemptTime - 900000 &&
          existing.attempts >= 10
        )
          fail("Too many attempts. Try again in 15 minutes.", 429);
        await tx.execute({
          sql: "INSERT INTO auth_attempts(key,attempts,window_start) VALUES(?,1,?) ON CONFLICT(key) DO UPDATE SET attempts=CASE WHEN window_start<? THEN 1 ELSE attempts+1 END, window_start=CASE WHEN window_start<? THEN ? ELSE window_start END",
          args: [key, attemptTime, attemptTime - 900000, attemptTime - 900000, attemptTime],
        });
      }
    });
  };
  return async (body, token, ip = "local") => {
    const action = body?.action;
    if (action === "health") {
      await db.execute("SELECT id FROM workspaces LIMIT 1");
      return { ready: true };
    }
    if (action === "signup" || action === "login") {
      const username = text(body.username, "username", 100).toLowerCase();
      if (!/^[a-z0-9_.@+-]{3,100}$/.test(username))
        fail("Use 3–100 letters, numbers, or email characters for username.");
      await throttle(ip, username);
      if (action === "signup") {
        if (
          !env.SETUP_CODE ||
          !secureEqual(String(body.setupCode ?? ""), env.SETUP_CODE)
        )
          fail("A valid workspace setup code is required.", 403);
        checkPassword(body.password);
        const name = text(body.name, "owner name"),
          gymName = text(body.gymName, "workspace name");
        const salt = randomBytes(32).toString("hex"),
          hash = await passwordHash(body.password, salt);
        const account = { id: randomUUID(), name };
        await transaction(db, async (tx) => {
          const exists = await tx.execute({
            sql: "SELECT id FROM accounts WHERE username=?",
            args: [username],
          });
          if (exists.rows.length)
            fail("This username is already registered.", 409);
          await tx.execute({
            sql: "INSERT INTO accounts VALUES(?,?,?,?,?,?)",
            args: [account.id, name, username, hash, salt, now()],
          });
          const w = randomUUID();
          await tx.execute({
            sql: "INSERT INTO workspaces VALUES(?,?,?,?)",
            args: [w, account.id, gymName, now()],
          });
          await setSettings(tx, w, {
            gym_name: gymName,
            currency: "PKR",
            country_code: "92",
            timezone: defaultTimeZone,
          });
        });
        return session(account);
      }
      if (typeof body.password !== "string" || body.password.length > 256)
        fail("Invalid username or password.", 401);
      const account = (
        await db.execute({
          sql: "SELECT * FROM accounts WHERE username=?",
          args: [username],
        })
      ).rows[0];
      // Match KDF work even for unknown usernames to reduce account enumeration.
      const hash = await passwordHash(
        body.password,
        account?.salt ?? "0".repeat(64),
      );
      if (!account || !secureEqual(hash, account.password_hash))
        fail("Invalid username or password.", 401);
      return session(account);
    }
    const account = await authenticate(token);
    if (action === "session")
      return {
        ownerName: account.name,
        workspaces: (
          await db.execute({
            sql: "SELECT id,name FROM workspaces WHERE owner_id=? ORDER BY created_at",
            args: [account.id],
          })
        ).rows,
      };
    if (action === "logout") {
      await db.execute({
        sql: "DELETE FROM cloud_sessions WHERE token_hash=?",
        args: [hashToken(token)],
      });
      return { ok: true };
    }
    if (action === "password") {
      checkPassword(body.next);
      const current = (
        await db.execute({
          sql: "SELECT * FROM accounts WHERE id=?",
          args: [account.id],
        })
      ).rows[0];
      if (
        typeof body.current !== "string" ||
        body.current.length > 256 ||
        !secureEqual(
          await passwordHash(body.current, current.salt),
          current.password_hash,
        )
      )
        fail("Current password is incorrect.", 403);
      const salt = randomBytes(32).toString("hex"),
        hash = await passwordHash(body.next, salt);
      await transaction(db, async (tx) => {
        await tx.execute({
          sql: "UPDATE accounts SET salt=?,password_hash=? WHERE id=?",
          args: [salt, hash, account.id],
        });
        await tx.execute({
          sql: "DELETE FROM cloud_sessions WHERE account_id=?",
          args: [account.id],
        });
      });
      return session(account);
    }
    if (action === "createWorkspace") {
      const name = text(body.name, "workspace name"),
        w = randomUUID();
      await transaction(db, async (tx) => {
        await tx.execute({
          sql: "INSERT INTO workspaces VALUES(?,?,?,?)",
          args: [w, account.id, name, now()],
        });
        await setSettings(tx, w, {
          gym_name: name,
          currency: "PKR",
          country_code: "92",
          timezone: defaultTimeZone,
        });
      });
      return { id: w, name };
    }
    const w = text(body.workspaceId, "workspace ID", 80);
    if (
      !(
        await db.execute({
          sql: "SELECT id FROM workspaces WHERE id=? AND owner_id=?",
          args: [w, account.id],
        })
      ).rows.length
    )
      fail("Workspace access denied.", 403);
    if (action === "workspace")
      return {
        settings: Object.fromEntries(
          (
            await db.execute({
              sql: "SELECT key,value FROM settings WHERE workspace_id=?",
              args: [w],
            })
          ).rows.map((r) => [r.key, r.value]),
        ),
      };
    if (action === "settings") {
      await transaction(db, (tx) => setSettings(tx, w, body.values));
      return { ok: true };
    }
    if (action === "records") {
      const table = body.table;
      if (!tables.includes(table)) fail("Invalid record type.");
      const before =
        body.before == null ? Number.MAX_SAFE_INTEGER : idNumber(body.before);
      const result = await db.execute({
        sql: `SELECT * FROM ${table} WHERE workspace_id=? AND id<? ORDER BY id DESC LIMIT 501`,
        args: [w, before],
      });
      const rows = [];
      let bytes = 2;
      for (const source of result.rows.slice(0, 500)) {
        const row = clean(source),
          size = Buffer.byteLength(JSON.stringify(row));
        if (rows.length && bytes + size > 2 * 1024 * 1024) break;
        rows.push(row);
        bytes += size;
      }
      return {
        rows,
        next: rows.length < result.rows.length ? rows.at(-1).id : null,
      };
    }
    if (action === "save") {
      if (
        !tables.includes(body.table) ||
        ["attendance", "member_workout_assignments"].includes(body.table)
      )
        fail("Use the dedicated attendance or workout action.");
      const table = body.table,
        row = { ...body.row },
        id = row.id;
      delete row.id;
      // Renewal history is server-managed; clients may echo it but cannot reset it.
      if (table === "payments") delete row.renewal_applied;
      return transaction(db, async (tx) => {
        let requestHash;
        if (table === "payments" && body.operationId != null) {
          const key = text(body.operationId, "operation ID", 128);
          requestHash = hashToken(
            JSON.stringify({ row, renew: body.renew === true, id }),
          );
          const receipt = (
            await tx.execute({
              sql: "SELECT request_hash FROM mutation_receipts WHERE workspace_id=? AND key=?",
              args: [w, key],
            })
          ).rows[0];
          if (receipt) {
            if (receipt.request_hash !== requestHash)
              fail(
                "This payment was already processed. Refresh records before changing it.",
                409,
              );
            return { ok: true };
          }
        }
        let original;
        if (id != null) original = await one(tx, table, id, w);
        if (table === "payments" && original?.renewal_applied === 1 &&
            (row.member_id !== original.member_id || (row.plan_id ?? null) !== (original.plan_id ?? null))) {
          fail("A receipt with applied renewal cannot change member or plan.");
        }
        if (
          table === "members" &&
          id == null &&
          row.plan_id != null &&
          row.expiry_date == null
        ) {
          const plan = await one(tx, "membership_plans", row.plan_id, w);
          row.expiry_date = addCalendarDays(row.join_date, plan.duration_days, await workspaceTimeZone(tx, w));
        }
        await validate(tx, table, row, w, id);
        let savedId = id;
        if (id == null) savedId = await insert(tx, table, row, w);
        else {
          const keys = Object.keys(row);
          await tx.execute({
            sql: `UPDATE ${table} SET ${keys.map((k) => k + "=?").join(",")} WHERE id=? AND workspace_id=?`,
            args: [...Object.values(row), id, w],
          });
        }
        if (
          table === "payments" &&
          body.renew === true &&
          row.status === "completed" &&
          original?.renewal_applied !== 1 &&
          original?.status !== "completed"
        ) {
          if (!row.plan_id) fail("Choose a plan for renewal.");
          const plan = await one(tx, "membership_plans", row.plan_id, w),
            member = await one(tx, "members", row.member_id, w);
          const zone = await workspaceTimeZone(tx, w);
          const today = addCalendarDays(now(), 0, zone);
          const expiry = addCalendarDays(Math.max(member.expiry_date ?? 0, today), plan.duration_days, zone);
          await tx.execute({
            sql: "UPDATE members SET plan_id=?,status='active',expiry_date=? WHERE id=? AND workspace_id=?",
            args: [row.plan_id, expiry, row.member_id, w],
          });
          await tx.execute({
            sql: "UPDATE payments SET renewal_applied=1 WHERE id=? AND workspace_id=?",
            args: [savedId, w],
          });
        }
        if (requestHash) {
          await tx.execute({
            sql: "INSERT INTO mutation_receipts(workspace_id,key,request_hash,created_at) VALUES(?,?,?,?)",
            args: [w, body.operationId, requestHash, now()],
          });
        }
        return { ok: true };
      });
    }
    if (action === "delete") {
      const table = body.table;
      if (!tables.includes(table)) fail("Invalid record type.");
      await one(db, table, body.id, w);
      await db.execute({
        sql: `DELETE FROM ${table} WHERE id=? AND workspace_id=?`,
        args: [body.id, w],
      });
      return { ok: true };
    }
    if (action === "checkIn")
      return transaction(db, async (tx) => {
        const member = await one(tx, "members", body.memberId, w);
        const zone = await workspaceTimeZone(tx, w);
        if (
          member.status !== "active" ||
          (member.expiry_date != null && calendarDate(member.expiry_date, zone) < calendarDate(now(), zone))
        )
          fail("Only active members with valid membership can check in.");
        if (
          (
            await tx.execute({
              sql: "SELECT id FROM attendance WHERE workspace_id=? AND member_id=? AND check_out IS NULL",
              args: [w, body.memberId],
            })
          ).rows.length
        )
          fail("Member is already checked in.");
        await insert(
          tx,
          "attendance",
          {
            member_id: body.memberId,
            check_in: now(),
            notes:
              typeof body.notes === "string" ? body.notes.slice(0, 2000) : null,
          },
          w,
        );
        return { ok: true };
      });
    if (action === "checkOut") {
      await one(db, "attendance", body.id, w);
      await db.execute({
        sql: "UPDATE attendance SET check_out=? WHERE workspace_id=? AND id=? AND check_out IS NULL",
        args: [now(), w, body.id],
      });
      return { ok: true };
    }
    if (action === "assignWorkout")
      return transaction(db, async (tx) => {
        await one(tx, "members", body.memberId, w);
        await one(tx, "workout_plans", body.workoutId, w);
        await tx.execute({
          sql: "UPDATE member_workout_assignments SET status='completed' WHERE member_id=? AND workspace_id=? AND status='active'",
          args: [body.memberId, w],
        });
        await insert(
          tx,
          "member_workout_assignments",
          {
            member_id: body.memberId,
            workout_plan_id: body.workoutId,
            assigned_date: now(),
            status: "active",
          },
          w,
        );
        return { ok: true };
      });
    if (action === "generateFees")
      return transaction(db, async (tx) => {
        const period = text(body.period, "fee month", 7);
        if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(period))
          fail("Use a valid YYYY-MM month.");
        const date = Number(body.dueDate);
        if (!Number.isSafeInteger(date) || date < 0) fail("Invalid due date.");
        const result = await tx.execute({
          sql: "INSERT INTO fee_invoices(workspace_id,member_id,amount,due_date,period,description,status) SELECT m.workspace_id,m.id,p.price,?,?,?,'unpaid' FROM members m JOIN membership_plans p ON p.id=m.plan_id AND p.workspace_id=m.workspace_id WHERE m.workspace_id=? AND m.status='active' AND (m.expiry_date IS NULL OR m.expiry_date>=?) ON CONFLICT(workspace_id,member_id,period) DO NOTHING",
          args: [date, period, `Membership fee • ${period}`, w, addCalendarDays(now(), 0, await workspaceTimeZone(tx, w))],
        });
        return { created: result.rowsAffected };
      });
    if (action === "restore") {
      const backup = body.backup;
      if (
        backup?.format !== "fitguide-backup" ||
        backup.version !== 1 ||
        !backup.tables
      )
        fail("Choose a valid FitGuide backup.");
      return transaction(db, async (tx) => {
        for (const table of [...tables].reverse())
          await tx.execute({
            sql: `DELETE FROM ${table} WHERE workspace_id=?`,
            args: [w],
          });
        const maps = {},
          records = {},
          phones = new Set();
        for (const table of tables) {
          const rows =
            backup.tables[table] ?? (table === "fee_invoices" ? [] : null);
          if (!Array.isArray(rows)) fail("Backup is incomplete.");
          maps[table] = new Map();
          records[table] = new Map();
          let nextId = Number(
            (
              await tx.execute(
                `SELECT COALESCE(MAX(id),0)+1 AS next_id FROM ${table}`,
              )
            ).rows[0].next_id,
          );
          const statements = [];
          for (const original of rows) {
            if (!original || typeof original !== "object")
              fail("Invalid backup record.");
            const row = { ...original },
              oldId = idNumber(row.id);
            delete row.id;
            delete row.workspace_id;
            if (table === "payments") row.renewal_applied ??= row.status === "completed" ? 1 : 0;
            if (maps[table].has(oldId)) fail("Duplicate backup record ID.");
            for (const [key, target] of Object.entries(refs))
              if (row[key] != null) {
                const next = maps[target]?.get(row[key]);
                if (next == null)
                  fail("Backup contains an invalid linked record.");
                row[key] = next;
              }
            await validate(
              tx,
              table,
              row,
              w,
              null,
              records,
              table === "members" ? phones : null,
            );
            const newId = nextId++;
            maps[table].set(oldId, newId);
            records[table].set(newId, { ...row, id: newId });
            const keys = Object.keys(row);
            statements.push({
              sql: `INSERT INTO ${table}(id,workspace_id,${keys.join(",")}) VALUES(${Array(
                keys.length + 2,
              )
                .fill("?")
                .join(",")})`,
              args: [newId, w, ...Object.values(row)],
            });
          }
          // Batch each table instead of one network round trip per backup row.
          for (let offset = 0; offset < statements.length; offset += 200)
            await tx.batch(statements.slice(offset, offset + 200));
        }
        if (!Array.isArray(backup.tables.settings))
          fail("Backup settings are missing.");
        const values = Object.fromEntries(
          backup.tables.settings
            .filter((r) => allowedSettings.has(r.key))
            .map((r) => [r.key, r.value]),
        );
        await tx.execute({
          sql: "DELETE FROM settings WHERE workspace_id=?",
          args: [w],
        });
        await setSettings(tx, w, values);
        return { ok: true };
      });
    }
    fail("Unknown action.", 404);
  };
}
