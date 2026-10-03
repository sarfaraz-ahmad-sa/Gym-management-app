PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS accounts (id TEXT PRIMARY KEY, name TEXT NOT NULL, username TEXT NOT NULL UNIQUE, password_hash TEXT NOT NULL, salt TEXT NOT NULL, created_at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS workspaces (id TEXT PRIMARY KEY, owner_id TEXT NOT NULL REFERENCES accounts(id), name TEXT NOT NULL, created_at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS cloud_sessions (token_hash TEXT PRIMARY KEY, account_id TEXT NOT NULL REFERENCES accounts(id), expires_at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS settings (workspace_id TEXT NOT NULL REFERENCES workspaces(id), key TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY(workspace_id,key));
CREATE TABLE IF NOT EXISTS auth_attempts (key TEXT PRIMARY KEY, attempts INTEGER NOT NULL, window_start INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS membership_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT, workspace_id TEXT NOT NULL REFERENCES workspaces(id), name TEXT NOT NULL,
        description TEXT, price REAL NOT NULL, duration_days INTEGER NOT NULL,
        features TEXT);
CREATE TABLE IF NOT EXISTS trainers (
        id INTEGER PRIMARY KEY AUTOINCREMENT, workspace_id TEXT NOT NULL REFERENCES workspaces(id), name TEXT NOT NULL,
        phone TEXT NOT NULL, email TEXT, specialization TEXT, hire_date INTEGER,
        status TEXT DEFAULT 'active');
CREATE TABLE IF NOT EXISTS members (
        id INTEGER PRIMARY KEY AUTOINCREMENT, workspace_id TEXT NOT NULL REFERENCES workspaces(id), name TEXT NOT NULL,
        phone TEXT NOT NULL, email TEXT, address TEXT, join_date INTEGER,
        plan_id INTEGER REFERENCES membership_plans(id), status TEXT DEFAULT 'active',
        trainer_id INTEGER REFERENCES trainers(id), expiry_date INTEGER, goal TEXT);
CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT, workspace_id TEXT NOT NULL REFERENCES workspaces(id), member_id INTEGER NOT NULL REFERENCES members(id),
        check_in INTEGER NOT NULL, check_out INTEGER, notes TEXT);
CREATE TABLE IF NOT EXISTS fee_invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT, workspace_id TEXT NOT NULL REFERENCES workspaces(id), member_id INTEGER NOT NULL REFERENCES members(id),
        amount REAL NOT NULL, due_date INTEGER NOT NULL, period TEXT,
        description TEXT, status TEXT NOT NULL DEFAULT 'unpaid', UNIQUE(workspace_id, member_id, period));
CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT, workspace_id TEXT NOT NULL REFERENCES workspaces(id), member_id INTEGER NOT NULL REFERENCES members(id),
        plan_id INTEGER REFERENCES membership_plans(id), amount REAL NOT NULL,
        payment_date INTEGER NOT NULL, status TEXT NOT NULL,
        payment_method TEXT, transaction_id TEXT, invoice_id INTEGER REFERENCES fee_invoices(id));
CREATE TABLE IF NOT EXISTS inventory_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT, workspace_id TEXT NOT NULL REFERENCES workspaces(id), name TEXT NOT NULL, category TEXT NOT NULL,
        quantity INTEGER NOT NULL, condition TEXT, purchase_price REAL,
        purchase_date INTEGER, notes TEXT);
CREATE TABLE IF NOT EXISTS workout_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT, workspace_id TEXT NOT NULL REFERENCES workspaces(id), name TEXT NOT NULL,
        description TEXT, level TEXT, duration_weeks INTEGER);
CREATE TABLE IF NOT EXISTS member_workout_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT, workspace_id TEXT NOT NULL REFERENCES workspaces(id), member_id INTEGER NOT NULL REFERENCES members(id),
        workout_plan_id INTEGER NOT NULL REFERENCES workout_plans(id),
        assigned_date INTEGER NOT NULL, status TEXT DEFAULT 'active');
CREATE INDEX IF NOT EXISTS idx_membership_plans_workspace ON membership_plans(workspace_id,id);
CREATE INDEX IF NOT EXISTS idx_trainers_workspace ON trainers(workspace_id,id);
CREATE INDEX IF NOT EXISTS idx_members_workspace ON members(workspace_id,id);
CREATE INDEX IF NOT EXISTS idx_attendance_workspace ON attendance(workspace_id,id);
CREATE INDEX IF NOT EXISTS idx_fee_invoices_workspace ON fee_invoices(workspace_id,id);
CREATE INDEX IF NOT EXISTS idx_payments_workspace ON payments(workspace_id,id);
CREATE INDEX IF NOT EXISTS idx_inventory_items_workspace ON inventory_items(workspace_id,id);
CREATE INDEX IF NOT EXISTS idx_workout_plans_workspace ON workout_plans(workspace_id,id);
CREATE INDEX IF NOT EXISTS idx_member_workout_assignments_workspace ON member_workout_assignments(workspace_id,id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_open_visit ON attendance(workspace_id,member_id) WHERE check_out IS NULL;
CREATE INDEX IF NOT EXISTS idx_workspace_owner ON workspaces(owner_id);
CREATE INDEX IF NOT EXISTS idx_session_expiry ON cloud_sessions(expires_at);
CREATE TABLE IF NOT EXISTS mutation_receipts (workspace_id TEXT NOT NULL REFERENCES workspaces(id), key TEXT NOT NULL, request_hash TEXT NOT NULL, created_at INTEGER NOT NULL, PRIMARY KEY(workspace_id,key));
