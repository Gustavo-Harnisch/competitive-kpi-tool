# GitHub Projects automation package

This package creates or reuses the repository, labels, milestones, GitHub Project, custom fields, issues, project items, and field values declared in `planning/project.json`.

## Requirements

- Python 3.10 or newer.
- GitHub CLI (`gh`).
- An authenticated account allowed to create the repository and Project.
- The `project` OAuth scope, or a `GH_TOKEN`/`PROJECTS_TOKEN` with repository and Projects permissions.

## Validate without changing GitHub

```bash
./setup_project.sh --dry-run --limit 5
```

Dry-run validates JSON, duplicate identifiers, field values, milestone references, labels, dates, and issue structure. It prints the first planned issues and does not require GitHub CLI.

## Synchronize

```bash
./setup_project.sh
```

Useful options:

```bash
./setup_project.sh --limit 5
./setup_project.sh --resume
./setup_project.sh --resume-from CKT-013
./setup_project.sh --state-file .sync-state.json
./setup_project.sh --config planning/project.json
```

The synchronizer is idempotent: it identifies issues by the `[CKT-NNN]` prefix, reuses fields and milestones by exact name, reuses the Project by title, and reuses Project items by issue URL.

## Authentication behavior

When no `GH_TOKEN` is present, the script runs `gh auth refresh -h github.com -s project` before mutation so the required scope can be granted. In GitHub Actions, `PROJECTS_TOKEN` is mapped to `GH_TOKEN`; the token must already have the required permissions.

## Source of truth

Do not hand-edit generated Issues as a substitute for updating planning. Change `planning/project.json`, review with dry-run, and synchronize again.

## Views

The JSON contains nine view designs. Public GitHub CLI commands do not provide equivalent creation and full configuration for all Project views, so the package creates the data model and documents the exact views without pretending they were automated.
