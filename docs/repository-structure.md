# Repository structure and migration plan

```text
competitive-kpi-tool/
├── .github/workflows/
├── automation-package/
├── benchmarks/
├── docs/
├── examples/
├── scripts/
├── src/
│   ├── core/
│   ├── data/
│   ├── services/
│   └── ui/
├── tests/
├── README.md
├── LICENSE
└── SECURITY.md
```

## Incremental migration

Because the inspected repository contained no application source, there is no code migration conflict. Use the following safe sequence:

1. Create a branch named `bootstrap/generated-baseline`.
2. Copy the generated repository into the empty target repository.
3. Commit the original uploaded configuration files under `docs/source-request/` if historical traceability is desired.
4. Run validation and open the project in Lazarus.
5. Tag the accepted baseline as `v0.1.0-alpha.1`.
6. Implement roadmap issues in order, keeping schema changes backward-compatible and backed up before migrations.

For future migrations, create a dated archive or Git tag before moving files, and perform structural refactors separately from behavioral changes.
