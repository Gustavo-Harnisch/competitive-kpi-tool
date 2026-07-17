# Competitive KPI Tool

A local-first desktop application for recording competitive-programming practice and converting it into transparent, verifiable KPIs. The initial implementation uses **Object Pascal**, **Lazarus**, **SQLite**, and dependency-light CSV/SQL export.

## Portfolio value

This repository demonstrates desktop application design, relational data modeling, parameterized SQL, transactions, CSV and SQL export, testable domain logic, GitHub automation, CI planning, and maintainable documentation.

## Current delivery

The uploaded repository contained configuration files only and no Lazarus source code. This generated package therefore provides:

- a runnable starter application architecture;
- SQLite persistence for settings and practice sessions;
- daily progress, seven-day average, total sessions, and streak KPIs;
- CSV and SQL export services;
- a 24-week roadmap with 24 implementation issues;
- an idempotent GitHub Projects automation package;
- diagnostic, architecture, security, validation, and release documentation.

## Build

Open `src/competitive_kpi_tool.lpi` in Lazarus and select **Run → Build**. The application requires Lazarus/FPC packages `LCL`, `SQLDB`, and `SQLite3Conn`.

On Linux, after installing Lazarus:

```bash
./scripts/build.sh
```

## Data location

The database is created in the operating system's per-user application configuration directory under `competitive-kpi-tool/competitive_kpi.sqlite3`. No network connection is required.

## Backup example

The file `examples/sample_backup.sql` is a sample backup for **SQLite**. It can be applied with tools such as `sqlite3` or DB Browser for SQLite.

The sample schema uses `id INTEGER PRIMARY KEY`. In SQLite this already auto-generates integer IDs when the application inserts a row without an explicit `id`, and it avoids false syntax errors from tools that validate the file as generic SQL instead of SQLite SQL.

Example with the SQLite command-line tool:

```bash
sqlite3 competitive_kpi.sqlite3 < examples/sample_backup.sql
```

This SQL file is not intended for MySQL, PostgreSQL, SQL Server, or Oracle without adapting the syntax.

## Automation

See [`automation-package/README.md`](automation-package/README.md). The source of truth for repository planning is `automation-package/planning/project.json`.

## Status

This is a professional starter repository, not a completed v1.0 application. The generated code covers the first usable vertical slice; the roadmap defines the remaining production work and validation.

## License

MIT.
