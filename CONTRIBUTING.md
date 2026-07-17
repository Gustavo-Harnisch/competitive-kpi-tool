# Contributing

1. Open an issue before substantial changes.
2. Keep UI, domain logic, services, and SQL responsibilities separated.
3. Use parameterized SQL for every value originating outside the source code.
4. Add or update tests for changed KPI behavior.
5. Run `./scripts/validate.sh` before opening a pull request.
6. Keep commits focused and use imperative commit subjects.

The project favors standard Lazarus/FPC packages and small, justified dependencies.
