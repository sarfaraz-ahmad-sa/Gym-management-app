import test from "node:test";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import assert from "node:assert/strict";
import { createClient } from "@libsql/client";
import { migrate } from "./schema.js";
import { createService } from "./service.js";

async function fixture(options = {}) {
  const dir = mkdtempSync(join(tmpdir(), "fitguide-api-test-"));
  const db = createClient({ url: "file:" + join(dir, "test.db") });
  const originalClose = db.close.bind(db);
  db.close = () => {
    originalClose();
    rmSync(dir, { recursive: true, force: true });
  };
  await migrate(db);
  const call = createService(db, { SETUP_CODE: "test-private-setup" }, options);
  const a = await call(
    {
      action: "signup",
      username: "owner.one",
      name: "Owner",
      gymName: "Alpha Gym",
      password: "Password123!",
      setupCode: "test-private-setup",
    },
    null,
    "first",
  );
  const b = await call(
    {
      action: "signup",
      username: "owner.two",
      name: "Owner Two",
      gymName: "Beta Gym",
      password: "Password123!",
      setupCode: "test-private-setup",
    },
    null,
    "second",
  );
  const w = a.workspaces[0].id;
  const request = (action, values = {}) =>
    call({ action, workspaceId: w, ...values }, a.token, "first");
  await request("save", {
    table: "membership_plans",
    row: { name: "Monthly", price: 3000, duration_days: 30 },
  });
  const plan = (await request("records", { table: "membership_plans" }))
    .rows[0];
  await request("save", {
    table: "members",
    row: {
      name: "Sarfaraz",
      phone: "03001234567",
      plan_id: plan.id,
      join_date: Date.now(),
      status: "active",
    },
  });
  const member = (await request("records", { table: "members" })).rows[0];
  return { db, call, a, b, w, request, plan, member };
}
test("registration needs private setup code; login is verified and sessions revoke", async () => {
  const f = await fixture();
  try {
    await assert.rejects(
      f.call(
        {
          action: "signup",
          username: "attacker",
          name: "X",
          gymName: "X",
          password: "Password123!",
          setupCode: "wrong",
        },
        null,
        "evil",
      ),
      /setup code/,
    );
    await assert.rejects(
      f.call(
        { action: "login", username: "owner.one", password: "wrong" },
        null,
        "login",
      ),
      /Invalid username/,
    );
    const login = await f.call(
      { action: "login", username: "owner.one", password: "Password123!" },
      null,
      "login",
    );
    assert.equal(login.ownerName, "Owner");
    await f.call({ action: "logout" }, login.token);
    await assert.rejects(f.call({ action: "session" }, login.token), /expired/);
  } finally {
    f.db.close();
  }
});
test("all workspace reads and foreign keys are isolated; parameterized fields block injection", async () => {
  const f = await fixture();
  try {
    await assert.rejects(
      f.call(
        { action: "records", table: "members", workspaceId: f.w },
        f.b.token,
      ),
      /denied/,
    );
    await assert.rejects(
      f.call(
        {
          action: "save",
          table: "payments",
          workspaceId: f.b.workspaces[0].id,
          row: {
            member_id: f.member.id,
            amount: 100,
            status: "completed",
            payment_date: Date.now(),
          },
        },
        f.b.token,
      ),
      /not found/,
    );
    await assert.rejects(
      f.request("records", { table: "members; DROP TABLE accounts;" }),
      /Invalid record/,
    );
    await assert.rejects(
      f.request("save", {
        table: "members",
        row: { ...f.member, workspace_id: f.w },
      }),
      /Unknown field/,
    );
    const extra = await f.request("createWorkspace", {
      name: "My Second Club",
    });
    assert.equal(extra.name, "My Second Club");
    assert.equal(
      (
        await f.call(
          { action: "records", workspaceId: extra.id, table: "members" },
          f.a.token,
        )
      ).rows.length,
      0,
    );
  } finally {
    f.db.close();
  }
});
test("monthly billing is idempotent and partial payments preserve the outstanding balance", async () => {
  const f = await fixture();
  try {
    assert.equal(
      (
        await f.request("generateFees", {
          period: "2026-10",
          dueDate: Date.now(),
        })
      ).created,
      1,
    );
    assert.equal(
      (
        await f.request("generateFees", {
          period: "2026-10",
          dueDate: Date.now(),
        })
      ).created,
      0,
    );
    const invoice = (await f.request("records", { table: "fee_invoices" }))
      .rows[0];
    await f.request("save", {
      table: "payments",
      row: {
        member_id: f.member.id,
        invoice_id: invoice.id,
        amount: 1000,
        payment_date: Date.now(),
        status: "completed",
      },
    });
    const paid = (
      await f.request("records", { table: "payments" })
    ).rows.reduce((n, p) => n + p.amount, 0);
    assert.equal(invoice.amount - paid, 2000);
    await assert.rejects(
      f.request("save", {
        table: "fee_invoices",
        row: { ...invoice, status: "void" },
      }),
      /cannot be voided/,
    );
    await assert.rejects(
      f.request("delete", { table: "members", id: f.member.id }),
    );
  } finally {
    f.db.close();
  }
});
test("renewal is atomic and editing completed receipt does not renew twice", async () => {
  const f = await fixture();
  try {
    const initial = f.member.expiry_date;
    await assert.rejects(
      f.request("save", {
        table: "payments",
        renew: true,
        row: {
          member_id: f.member.id,
          amount: 3000,
          status: "completed",
          payment_date: Date.now(),
        },
      }),
      /Choose a plan/,
    );
    assert.equal(
      (await f.request("records", { table: "payments" })).rows.length,
      0,
    );
    await f.request("save", {
      table: "payments",
      renew: true,
      row: {
        member_id: f.member.id,
        plan_id: f.plan.id,
        amount: 3000,
        status: "completed",
        payment_date: Date.now(),
      },
    });
    const after = (await f.request("records", { table: "members" })).rows[0]
      .expiry_date;
    assert.equal(after - initial, 30 * 86400000);
    const receipt = (await f.request("records", { table: "payments" })).rows[0];
    await f.request("save", { table: "payments", renew: true, row: receipt });
    assert.equal(
      (await f.request("records", { table: "members" })).rows[0].expiry_date,
      after,
    );
  } finally {
    f.db.close();
  }
});
test("attendance rejects duplicates and expired memberships", async () => {
  const f = await fixture();
  try {
    await f.request("checkIn", { memberId: f.member.id });
    await assert.rejects(
      f.request("checkIn", { memberId: f.member.id }),
      /already/,
    );
    const visit = (await f.request("records", { table: "attendance" })).rows[0];
    await f.request("checkOut", { id: visit.id });
    await f.request("save", {
      table: "members",
      row: { ...f.member, join_date: 1, expiry_date: 2 },
    });
    await assert.rejects(
      f.request("checkIn", { memberId: f.member.id }),
      /valid membership/,
    );
  } finally {
    f.db.close();
  }
});
test("backup restore remaps IDs, protects another workspace and rolls back invalid records", async () => {
  const f = await fixture();
  try {
    await f.request("generateFees", { period: "2026-10", dueDate: Date.now() });
    const tables = {};
    for (const table of [
      "membership_plans",
      "trainers",
      "members",
      "fee_invoices",
      "attendance",
      "payments",
      "inventory_items",
      "workout_plans",
      "member_workout_assignments",
    ])
      tables[table] = (await f.request("records", { table })).rows;
    tables.settings = [{ key: "gym_name", value: "Restored Alpha" }];
    const backup = { format: "fitguide-backup", version: 1, tables };
    await f.call(
      { action: "restore", workspaceId: f.b.workspaces[0].id, backup },
      f.b.token,
    );
    const imported = (
      await f.call(
        {
          action: "records",
          workspaceId: f.b.workspaces[0].id,
          table: "members",
        },
        f.b.token,
      )
    ).rows[0];
    assert.notEqual(imported.id, f.member.id);
    const invoice = (
      await f.call(
        {
          action: "records",
          workspaceId: f.b.workspaces[0].id,
          table: "fee_invoices",
        },
        f.b.token,
      )
    ).rows[0];
    assert.equal(invoice.member_id, imported.id);
    assert.equal(
      (await f.request("records", { table: "members" })).rows[0].id,
      f.member.id,
    );
    backup.tables.members[0].plan_id = 987654;
    await assert.rejects(f.request("restore", { backup }), /invalid linked/);
    assert.equal(
      (await f.request("records", { table: "members" })).rows[0].id,
      f.member.id,
    );
  } finally {
    f.db.close();
  }
});
test("password change verifies password and revokes other sessions; rate limits persist", async () => {
  const f = await fixture();
  try {
    await assert.rejects(
      f.request("password", { current: "wrong", next: "NewPassword123!" }),
      /incorrect/,
    );
    const changed = await f.request("password", {
      current: "Password123!",
      next: "NewPassword123!",
    });
    assert.ok(changed.token);
    await assert.rejects(f.call({ action: "session" }, f.a.token), /expired/);
    for (let i = 0; i < 10; i++)
      await assert.rejects(
        f.call(
          { action: "login", username: "nonexistent", password: "wrong" },
          null,
          "abuse",
        ),
        /Invalid/,
      );
    await assert.rejects(
      f.call(
        { action: "login", username: "nonexistent", password: "wrong" },
        null,
        "abuse",
      ),
      /Too many/,
    );
  } finally {
    f.db.close();
  }
});
test("payment retry with the same operation ID cannot create a duplicate receipt", async () => {
  const f = await fixture();
  try {
    const values = {
      table: "payments",
      operationId: "repeat-payment-unique-key",
      row: {
        member_id: f.member.id,
        amount: 3000,
        payment_date: Date.now(),
        status: "completed",
      },
    };
    await f.request("save", values);
    await f.request("save", values);
    assert.equal(
      (await f.request("records", { table: "payments" })).rows.length,
      1,
    );
    values.row.amount = 500;
    await assert.rejects(f.request("save", values), /already processed/);
  } finally {
    f.db.close();
  }
});

test('linked receipts prevent invoice reassignment and the backup remains restorable', async () => {
  const f = await fixture();
  try {
    await f.request('save', {table: 'members', row: {name: 'Second', phone: '03005558888', status: 'active', join_date: Date.now()}});
    const second = (await f.request('records', {table: 'members'})).rows.find(m => m.id !== f.member.id);
    await f.request('generateFees', {period: '2026-10', dueDate: Date.now()});
    const invoice = (await f.request('records', {table: 'fee_invoices'})).rows[0];
    await f.request('save', {table: 'payments', row: {member_id: f.member.id, invoice_id: invoice.id, amount: 1000, payment_date: Date.now(), status: 'pending'}});
    await assert.rejects(f.request('save', {table: 'fee_invoices', row: {...invoice, member_id: second.id}}), /linked payments cannot change member/);
    const receipt = (await f.request('records', {table: 'payments'})).rows[0];
    await f.request('save', {table: 'payments', row: {...receipt, status: 'completed'}});
    await assert.rejects(f.request('save', {table: 'fee_invoices', row: {...invoice, member_id: second.id}}), /linked payments cannot change member/);
    const data = {};
    for (const table of ['membership_plans','trainers','members','fee_invoices','attendance','payments','inventory_items','workout_plans','member_workout_assignments']) data[table] = (await f.request('records', {table})).rows;
    data.settings = [{key: 'gym_name', value: 'Restored'}];
    await f.call({action: 'restore', workspaceId: f.b.workspaces[0].id, backup: {format: 'fitguide-backup', version: 1, tables: data}}, f.b.token);
    assert.equal((await f.request('records', {table: 'fee_invoices'})).rows[0].member_id, f.member.id);
  } finally {f.db.close();}
});

test('renewal survives payment status cycles, attempted flag resets and backup restore', async () => {
  const f = await fixture();
  try {
    await f.request('save', {table: 'payments', renew: true, row: {member_id: f.member.id, plan_id: f.plan.id, amount: 3000, status: 'completed', payment_date: Date.now()}});
    const expiry = (await f.request('records', {table: 'members'})).rows[0].expiry_date;
    let receipt = (await f.request('records', {table: 'payments'})).rows[0];
    assert.equal(receipt.renewal_applied, 1);
    await f.request('save', {table: 'payments', row: {...receipt, status: 'pending', renewal_applied: 0}});
    await f.request('save', {table: 'payments', renew: true, row: {...receipt, status: 'completed', renewal_applied: 0}});
    assert.equal((await f.request('records', {table: 'members'})).rows[0].expiry_date, expiry);
    const data = {};
    for (const table of ['membership_plans','trainers','members','fee_invoices','attendance','payments','inventory_items','workout_plans','member_workout_assignments']) data[table] = (await f.request('records', {table})).rows;
    data.settings = [{key:'gym_name',value:'Alpha Gym'},{key:'timezone',value:'Asia/Karachi'}];
    await f.request('restore', {backup: {format: 'fitguide-backup', version: 1, tables: data}});
    receipt = (await f.request('records', {table:'payments'})).rows[0];
    await f.request('save', {table:'payments', row:{...receipt,status:'pending'}});
    await f.request('save', {table:'payments', renew:true,row:{...receipt,status:'completed'}});
    assert.equal((await f.request('records', {table:'members'})).rows[0].expiry_date, expiry);
    await assert.rejects(f.request('save', {table:'payments',row:{...receipt,plan_id:null}}), /cannot change member or plan/);
  } finally {f.db.close();}
});

test('workspace calendar permits the entire Pakistan expiry day and rejects the following day', async () => {
  let current = Date.parse('2026-10-08T17:59:00Z'); // 10:59 pm Pakistan.
  const f = await fixture({now: () => current});
  try {
    await f.request('save', {table:'members',row:{...f.member,join_date:1,expiry_date:Date.parse('2026-10-07T19:00:00Z')}});
    await f.request('checkIn', {memberId:f.member.id});
    const visit = (await f.request('records',{table:'attendance'})).rows[0];
    await f.request('checkOut',{id:visit.id});
    current = Date.parse('2026-10-08T19:00:00Z');
    await assert.rejects(f.request('checkIn',{memberId:f.member.id}),/valid membership/);
    await assert.rejects(f.request('settings',{values:{timezone:'MadeUp/Zone'}}),/valid IANA timezone/);
  } finally {f.db.close();}
});

test('migration preserves legacy completed receipts and is safe to rerun', async () => {
  const f = await fixture();
  try {
    await f.db.execute('ALTER TABLE payments DROP COLUMN renewal_applied');
    await f.request('save',{table:'payments',row:{member_id:f.member.id,plan_id:f.plan.id,amount:3000,status:'completed',payment_date:Date.now()}});
    await migrate(f.db);
    await migrate(f.db);
    let receipt = (await f.request('records',{table:'payments'})).rows[0];
    assert.equal(receipt.renewal_applied,1);
    const expiry = (await f.request('records',{table:'members'})).rows[0].expiry_date;
    await f.request('save',{table:'payments',row:{...receipt,status:'pending'}});
    await f.request('save',{table:'payments',renew:true,row:{...receipt,status:'completed'}});
    assert.equal((await f.request('records',{table:'members'})).rows[0].expiry_date,expiry);
  } finally {f.db.close();}
});
