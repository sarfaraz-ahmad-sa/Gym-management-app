import test from 'node:test';
import assert from 'node:assert/strict';
import {addCalendarDays, calendarDate, validTimeZone} from './calendar.js';

test('calendar dates agree across UTC and Pakistan day boundaries', () => {
  assert.equal(calendarDate(Date.parse('2026-10-07T19:00Z'),'Asia/Karachi'),'2026-10-08');
  assert.equal(addCalendarDays(Date.parse('2026-10-08T12:00Z'),0,'Asia/Karachi'),Date.parse('2026-10-07T19:00Z'));
  assert.equal(addCalendarDays(Date.parse('2026-10-07T19:00Z'),30,'Asia/Karachi'),Date.parse('2026-11-06T19:00Z'));
  assert.equal(validTimeZone('Asia/Karachi'),true);
  assert.equal(validTimeZone('invalid/zone'),false);
});

test('renewal adds calendar days across daylight saving changes', () => {
  const before = Date.parse('2026-03-07T05:00Z');
  assert.equal(addCalendarDays(before,2,'America/New_York'),Date.parse('2026-03-09T04:00Z'));
  const autumn = Date.parse('2026-10-31T04:00Z');
  assert.equal(addCalendarDays(autumn,2,'America/New_York'),Date.parse('2026-11-02T05:00Z'));
});
