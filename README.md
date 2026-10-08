# FitGuide Pro 3 — Flutter + Turso + Vercel

One Flutter codebase for Android, iOS and responsive web. The deployed web app and mobile app use the same authenticated Node API and Turso/libSQL SQL database. Turso credentials stay on the server; they are never included in the Flutter bundle.

## Included

- Owner registration with a private setup code, password login, 7-day sessions and password changes.
- Multiple workspaces per owner. Each workspace has isolated members, fees, receipts, visits, settings and exports.
- Dashboard: real 7/30/90-day revenue and attendance analytics, membership health, payment methods, plans, dues and gym operations.
- Workspace settings: name, PNG/JPEG/WebP logo (up to 190 KB), address, reception contact, opening hours, currency and country code.
- Members, trainers, membership plans, equipment, workouts and assignment history.
- Monthly fee invoices, custom invoices, partial payments and outstanding balances. Generating the same month twice skips existing invoices.
- Optional invoice link when recording a payment. Use **Fees & dues → Receive** to prefill the correct invoice and remaining amount. Unlinked completed receipts do not automatically settle an invoice. Legacy pending receipts without invoices remain included in dues.
- Explicit membership renewal on completed payment, with persistent renewal history that survives receipt status changes and backup/restore.
- Invoices with linked receipts cannot change member or be voided. Receipts with applied renewal cannot change member or plan.
- Workspace timezone (default Asia/Karachi) defines expiry dates, check-in, renewal and reporting. Membership is valid throughout its expiry date.
- Roman Urdu fee reminders with member name, actual outstanding amount, earliest due month/date, last completed receipt amount/date, workspace signature and customizable fitness line.
- Editable welcome/renewal/payment templates with placeholders. Review/copy a message or open WhatsApp; the user presses Send. No automatic message delivery is configured.
- Download all data as a ZIP containing a JSON backup, per-table CSV files and member balances. Individual module CSV and receipt text exports are also available. Mobile opens the system share/save sheet.
- Transactional JSON restore with IDs remapped to preserve other workspaces and the owner account. Passwords/sessions are excluded from workspace exports.
- Separate local SQLite demo. Production uses the shared API; no silent local fallback on network failure.
- Responsive Material 3 light/dark theme.
- Expired cloud sessions clear the stored token and return to sign-in. Mutations refresh their affected tables instead of all workspace history.

## UI and billing update

Apply the server and Flutter source together. The API automatically adds the renewal-history column on startup; local SQLite upgrades to version 5 without deleting existing records. Legacy completed receipts are conservatively treated as already renewed because older versions did not record whether renewal had been applied. Old backups remain supported.

Run `flutter pub get` before building to install the timezone dependency. Workspace timezone can be changed in Settings. Android release builds require your existing upload keystore configured through `android/key.properties`; `android/key.properties.example` shows the fields. Release builds no longer fall back to a debug key. iOS signing configuration is unchanged.

Verification for this update: **14 backend tests passed**, and **24 Dart business-logic tests passed** in a standalone harness using real SQLite and the real Node API. The harness substituted Flutter notification/preferences bindings; it did not render widgets. The included phone/iPad widget tests and native iOS/Android builds still need to be run with Flutter on a suitable machine.

Initial workspace loading still reads full paged history for the current dashboard and search. This update reduces mutation refreshes to affected tables; server summaries and fully lazy screen loading are future scalability work.

## Local development

Requirements: Flutter **3.47.6**, Node **22**, npm. Install dependencies:

```bash
flutter pub get
npm ci
```

For the development API, create a private `.env` from `.env.example` and set:

```dotenv
TURSO_DATABASE_URL=file:./development.db
SETUP_CODE=your-long-private-registration-code
ALLOWED_ORIGINS=http://localhost:8080
```

Start API and web in separate terminals:

```bash
node --env-file=.env server/dev.js
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://localhost:3000
```

The API initializes the schema automatically. `npm run migrate` is also available after loading environment variables. Use the login screen’s **Create an owner account & workspace** action and your setup code. Existing owners can create more workspaces in Settings.

## Turso database

Use a **libSQL-compatible** Turso Cloud database for this version (`@libsql/client`). Set the database URL and a database-scoped token in backend environment variables. Never use a Turso organization/admin token in the client.

If using the Turso CLI after signing in:

```bash
turso db create fitguide
turso db show fitguide --url
turso db tokens create fitguide
```

Keep the token private. `server/schema.sql` contains the cloud SQL schema. The API applies the same schema from `server/schema.js`; it does not delete existing cloud tables. For later schema changes use a versioned migration.

## Vercel deployment

Import the project root into Vercel (or deploy from CLI after `vercel login`). Framework preset: **Other**. The committed configuration installs Node dependencies, builds Flutter and publishes `build/web`; `api/gym.js` becomes a Node Function. API paths are excluded from SPA rewrites.

Add the following **server-side** environment variables for Production and Preview as needed:

| Variable | Purpose |
| --- | --- |
| `TURSO_DATABASE_URL` | Turso/libSQL cloud database URL |
| `TURSO_AUTH_TOKEN` | Database access token |
| `SETUP_CODE` | Private owner-registration code, not a public Flutter define |
| `ALLOWED_ORIGINS` | Optional comma-separated exact extra web origins; the same deployment origin is automatically allowed |

Optional prebuilt deployment: build with `flutter build web --release`, copy `build/web/` to `prebuilt-web/`, then run `vercel --local-config vercel.prebuilt.json --prod`. Keep the same server environment variables configured. The source ZIP includes the configuration; compiled output is generated by the build. Normal source builds use `vercel.json`.

Then deploy:

```bash
vercel deploy --prod
```

The web app uses `/api/gym` on its own origin, with no API URL hardcoded. Verify owner signup, create a plan/member, generate fees, receive a partial payment, export data and sign in from mobile. A production domain/URL cannot be supplied until the project is actually deployed with account access and Turso credentials.

**Hosting cost:** Vercel Hobby is restricted to personal, non-commercial use. A live gym business needs an appropriate Vercel plan. Turso’s free database quota is separate; neither database nor API hosting has unlimited usage. Do not interpret “free database” as “the complete commercial deployment is free forever.”

## Android and iOS

The same project includes `android/` and `ios/`. The Android release manifest includes Internet access. On mobile, enter the published FitGuide HTTPS server address on the login screen, then sign in with the same owner account as web. You can also embed only the public API address:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-DEPLOYED-DOMAIN
flutter build appbundle --release --dart-define=API_BASE_URL=https://YOUR-DEPLOYED-DOMAIN
flutter build ipa --release --dart-define=API_BASE_URL=https://YOUR-DEPLOYED-DOMAIN
```

Android SDK is needed for APK/AAB. Configure your own release keystore before Play Store upload; the template currently uses the development signing key for local release testing. iOS IPA requires macOS, Xcode, your Apple team and provisioning. No store publication or signing setup is performed by this code package.

Cloud records require an Internet connection. Cross-device changes appear on refresh/app resume; no realtime push subscription or offline cloud write queue is implemented. The local demo works independently.

## Daily backups and large imports

Settings exports download records in pages of 500 so the API never returns the whole database in one oversized response. For a point-in-time export, pause simultaneous editing while downloading; a paged client export is not an atomic snapshot across all pages. Large downloads still require enough device memory for the assembled ZIP.

The server backup script reads each workspace in one read transaction and writes compressed JSON files, without auth secrets:

```bash
node --env-file=.env server/backup.js
```

Set `BACKUP_DIRECTORY` to a protected folder on a separate server/disk. Run daily via your existing scheduler/cron, and copy that folder to a separate backup location. Automatic backup execution is **not active** merely because the script is included; configure the schedule and verify a restore first. Workspace backups do not include owner credentials, so keep database-level recovery configured for account recovery as well.

Cloud JSON restore through the app is limited to **3 MB**, below the Vercel request limit. For a larger backup use the trusted server restore script, which authenticates an existing owner and bypasses HTTP body-size limits. It still replaces only the chosen workspace:

```bash
RESTORE_USERNAME=owner-name RESTORE_WORKSPACE_ID=workspace-uuid RESTORE_FILE=/private/backup.json node --env-file=.env server/restore.js
```

The script prompts privately for the existing password and asks you to type the workspace ID to confirm replacement. Remote transactions have a timeout; extremely large restores should be performed using a dedicated maintenance migration rather than while members are checking in.

## Existing local SQLite records

Export a JSON backup from the previous app before changing code. Create your cloud owner/workspace, then restore that JSON in Settings. Older backups without `fee_invoices` are accepted. Unlinked old receipts are preserved. Local passwords and sessions are not transferred; use the new cloud owner account.

## Verification

```bash
npm test
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
```

Verified in this delivery: 18 Flutter tests, 8 backend tests, a clean Flutter analyzer and a release web build. Cloud integration tests run the real Node API against a local libSQL database; hosted Turso connectivity is not yet verified.

Tests cover authentication/rate limits, workspace isolation, foreign-reference protection, monthly billing, partial balances, atomic renewal/restore, attendance, responsive Flutter layouts and member forms. Actual hosted Turso/Vercel and physical mobile verification require the external accounts/platform tools.
