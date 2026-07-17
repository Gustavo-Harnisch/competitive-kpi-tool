-- Competitive KPI Tool sample export
BEGIN TRANSACTION;
INSERT INTO practice_sessions(id, practiced_on, platform, problems_solved, minutes_spent, notes, created_at) VALUES (1, '2026-07-20', 'Codeforces', 3, 90, 'Two greedy problems and one implementation problem', '2026-07-20 22:00:00');
INSERT INTO practice_sessions(id, practiced_on, platform, problems_solved, minutes_spent, notes, created_at) VALUES (2, '2026-07-21', 'CSES', 2, 60, 'Sorting and searching practice', '2026-07-21 22:00:00');
COMMIT;
