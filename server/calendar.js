export const defaultTimeZone = "Asia/Karachi";

export function validTimeZone(value) {
  if (typeof value !== "string" || !value || value.length > 100) return false;
  try {
    new Intl.DateTimeFormat("en", { timeZone: value }).format(0);
    return true;
  } catch {
    return false;
  }
}

export function calendarDate(timestamp, timeZone = defaultTimeZone) {
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat("en", {
      timeZone, year: "numeric", month: "2-digit", day: "2-digit",
    }).formatToParts(timestamp).map((p) => [p.type, p.value]),
  );
  return `${parts.year}-${parts.month}-${parts.day}`;
}

function offsetAt(timestamp, timeZone) {
  const name = new Intl.DateTimeFormat("en", {
    timeZone, timeZoneName: "longOffset",
  }).formatToParts(timestamp).find((p) => p.type === "timeZoneName").value;
  if (name === "GMT") return 0;
  const match = /^GMT([+-])(\d{2}):(\d{2})(?::(\d{2}))?$/.exec(name);
  if (!match) throw new Error("Unable to calculate workspace timezone.");
  return (match[1] === "+" ? 1 : -1) *
    (+match[2] * 3600000 + +match[3] * 60000 + +(match[4] ?? 0) * 1000);
}

export function addCalendarDays(timestamp, days, timeZone = defaultTimeZone) {
  const [year, month, day] = calendarDate(timestamp, timeZone).split("-").map(Number);
  const localMidnight = Date.UTC(year, month - 1, day + days);
  let result = localMidnight - offsetAt(timestamp, timeZone);
  for (let i = 0; i < 4; i++) {
    const next = localMidnight - offsetAt(result, timeZone);
    if (next === result) return result;
    result = next;
  }
  // Some regions advance their clocks at midnight. Choose the later valid
  // instant on that calendar date rather than a time on the previous day.
  return Math.max(result, localMidnight - offsetAt(result, timeZone));
}

export async function workspaceTimeZone(db, workspaceId) {
  const result = await db.execute({
    sql: "SELECT value FROM settings WHERE workspace_id=? AND key='timezone'",
    args: [workspaceId],
  });
  return result.rows[0]?.value || defaultTimeZone;
}
