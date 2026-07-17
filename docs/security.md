# Security model

## Assets

Local practice history, settings, notes, exports, and release artifacts.

## Main risks

- SQL injection from notes or platform names.
- Overwriting or exporting to unintended paths.
- Corrupted database after interrupted writes.
- Sensitive notes included in shared examples.
- Untrusted dependencies or release artifacts.

## Controls

- Parameterized SQL for all user values.
- SQLite constraints and transactions.
- Explicit file selection for exports.
- Offline-by-default operation.
- Minimal dependencies using Lazarus/FPC standard packages.
- No telemetry and no automatic network calls.
- Checksums and documented provenance for releases.

## Residual risks

Local administrators and malware with the user's privileges can read the database. SQLite files are not encrypted by default. Encryption is excluded from v1.0 unless a reviewed cross-platform strategy is selected.
