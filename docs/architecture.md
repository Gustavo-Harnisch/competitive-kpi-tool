# Architecture

## Style

The application uses a dependency-light layered architecture:

```text
UI (LCL forms)
  -> Services (export, reminder)
  -> Domain/Core (types, KPI formulas, paths)
  -> Data (SQLite through SQLDB)
```

The UI may orchestrate operations but must not construct SQL. The data layer may return primitive summaries and domain records but must not display dialogs. Pure KPI formulas remain independent of LCL and SQLite.

## Modules

| Module | Responsibility | Main files | Dependencies | Errors | Tests |
| --- | --- | --- | --- | --- | --- |
| Application bootstrap | Initialize LCL and main form | `src/competitive_kpi_tool.lpr` | LCL | Startup exception | Manual smoke test |
| Application paths | Resolve per-user data paths | `src/core/app_paths.pas` | RTL | Directory creation failure | Platform path test |
| Domain types | Stable session and KPI records | `src/core/kpi_types.pas` | RTL | Invalid record values handled by callers | Compilation and validation tests |
| KPI calculator | Pure percentages and averages | `src/core/kpi_calculator.pas` | Math | Empty input, zero goal | FPCUnit boundary tests |
| Database | Schema, transactions, parameterized queries | `src/data/kpi_database.pas` | SQLDB, SQLite3Conn | Connection, constraint, query errors | Temporary database integration tests |
| Export service | CSV and SQL portability | `src/services/export_service.pas` | Database, RTL | File I/O and escaping errors | Golden-file and restore tests |
| Reminder service | Decide whether an in-app reminder is due | `src/services/reminder_service.pas` | Domain/data | Missing settings | Deterministic decision tests |
| Main form | Data entry, KPI display, history, export | `src/ui/main_form.pas` | LCL, services, data | Actionable dialogs | UI smoke tests |

## Data invariants

- `problems_solved >= 0`.
- `minutes_spent >= 0`.
- Practice dates are stored as `YYYY-MM-DD` local dates.
- The settings table has exactly one logical row with `id = 1`.
- KPI percentages use a zero result when the goal is zero or invalid.
- Database schema creation and future migrations run inside transactions.

## Error handling

Recoverable user input problems are validated before persistence. Infrastructure exceptions are caught at the UI boundary and presented as concise actionable messages. Destructors release owned connections, transactions, and queries. Export writes to an explicitly selected file and never silently overwrites without the operating system dialog's confirmation behavior.

## Logging

The starter avoids a third-party logging dependency. A later implementation should add a small rotating text logger behind an interface, with data minimization and no session notes unless explicitly enabled.

## Extensibility

Future integrations should consume service interfaces rather than reach into forms or SQL. Potential adapters include Codeforces import, OS-native notifications, and read-only analytics dashboards. These are deferred until the local model and tests are stable.
