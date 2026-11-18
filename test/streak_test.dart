import 'package:flutter_test/flutter_test.dart';
import 'package:reading_management/data/database.dart';
import 'package:reading_management/features/stats/stats_providers.dart';

ReadingSession session(DateTime date, {int pagesRead = 10}) => ReadingSession(
      id: 1,
      workId: 1,
      date: date,
      pagesRead: pagesRead,
      note: null,
    );

void main() {
  final now = DateTime(2026, 11, 18);

  test('sem leitura', () {
    final streak = calculateStreak(const <ReadingSession>[], now: now);
    expect(streak.current, 0);
    expect(streak.best, 0);
    expect(streak.atRisk, false);
    expect(streak.readDays, isEmpty);
  });

  test('somente hoje', () {
    final streak = calculateStreak([session(now)], now: now);
    expect(streak.current, 1);
    expect(streak.best, 1);
    expect(streak.atRisk, false);
  });

  test('somente ontem mantém a sequência em risco', () {
    final streak = calculateStreak(
      [session(DateTime(2026, 11, 17))],
      now: now,
    );
    expect(streak.current, 1);
    expect(streak.best, 1);
    expect(streak.atRisk, true);
  });

  test('dois dias sem leitura zera a sequência atual', () {
    final streak = calculateStreak(
      [session(DateTime(2026, 11, 16))],
      now: now,
    );
    expect(streak.current, 0);
    expect(streak.atRisk, false);
  });

  test('buraco no meio', () {
    final streak = calculateStreak(
      [
        session(DateTime(2026, 11, 15)),
        session(DateTime(2026, 11, 16)),
        session(now),
      ],
      now: now,
    );
    expect(streak.current, 1);
    expect(streak.best, 2);
  });

  test('virada de mês', () {
    final reference = DateTime(2026, 11, 1);
    final streak = calculateStreak(
      [session(DateTime(2026, 10, 31)), session(reference)],
      now: reference,
    );
    expect(streak.current, 2);
    expect(streak.best, 2);
  });

  test('virada de ano', () {
    final reference = DateTime(2026, 1, 1);
    final streak = calculateStreak(
      [session(DateTime(2025, 12, 31)), session(reference)],
      now: reference,
    );
    expect(streak.current, 2);
    expect(streak.best, 2);
  });

  test('sessões com data passada e sessão apagada recalculam', () {
    final sessions = [
      session(DateTime(2026, 11, 16)),
      session(DateTime(2026, 11, 17)),
      session(now),
    ];
    expect(calculateStreak(sessions, now: now).current, 3);
    expect(calculateStreak(sessions, now: now).best, 3);

    sessions.removeAt(0);
    expect(calculateStreak(sessions, now: now).current, 2);
    expect(calculateStreak(sessions, now: now).best, 2);
  });

  test('sessões com zero páginas não contam', () {
    final streak = calculateStreak(
      [session(now, pagesRead: 0), session(DateTime(2026, 11, 17))],
      now: now,
    );
    expect(streak.current, 1);
    expect(streak.atRisk, true);
  });

  test('sessões futuras não contam', () {
    final streak = calculateStreak(
      [session(now), session(DateTime(2026, 11, 19))],
      now: now,
    );
    expect(streak.current, 1);
    expect(streak.readDays, {dayKey(now)});
  });
}
