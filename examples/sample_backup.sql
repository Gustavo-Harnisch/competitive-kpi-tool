-- SQLite sample backup.
-- Use this file with SQLite, for example with DB Browser for SQLite or sqlite3.

CREATE TABLE IF NOT EXISTS practice_sessions (
  id INTEGER PRIMARY KEY,
  practiced_on TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (length(platform) BETWEEN 1 AND 80),
  problems_solved INTEGER NOT NULL CHECK (problems_solved >= 0),
  minutes_spent INTEGER NOT NULL CHECK (minutes_spent >= 0),
  notes TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

BEGIN TRANSACTION;

DELETE FROM practice_sessions WHERE id IN (1, 2);

INSERT INTO practice_sessions(id, practiced_on, platform, problems_solved, minutes_spent, notes, created_at)
VALUES (1, '2026-07-20', 'Codeforces', 3, 90, 'Two greedy problems and one implementation problem', '2026-07-20 22:00:00');

INSERT INTO practice_sessions(id, practiced_on, platform, problems_solved, minutes_spent, notes, created_at)
VALUES (2, '2026-07-21', 'CSES', 2, 60, 'Sorting and searching practice', '2026-07-21 22:00:00');

COMMIT;
end;
