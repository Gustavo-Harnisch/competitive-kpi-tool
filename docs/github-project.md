# GitHub Projects design

## Fields

- **Status**: Backlog, Todo, In Progress, Blocked, In Review, Done.
- **Priority**: P0 through P3.
- **Phase**: Foundation, Architecture, Data Layer, Core Implementation, UX and Integrations, Quality, Release.
- **Module**: repository-specific single-select module.
- **Work type**: Feature, Design, Chore, Test, CI, Security, Performance, Documentation, Release.
- **Track**: free text for portfolio, quality, release, or future parallel tracks.
- **Complexity**: XS through XL.
- **Estimate**: numeric hours.
- **Start date** and **Target date**: roadmap boundaries.
- **Risk**: Low, Medium, High, Critical.
- **Version**: v0.1 through v1.0.

## Views

1. Master Table: grouped by Phase and sorted by Start date.
2. Development Board: board grouped by Status.
3. Roadmap: roadmap grouped by Phase using Start and Target dates.
4. Current Sprint: active work sorted by Priority and Target date.
5. Critical Work: P0 or High/Critical risk.
6. Testing: test work and testing module.
7. Documentation: documentation work.
8. Applications: product modules only.
9. Release 1.0: all v1.0 work sorted by priority.

GitHub's public CLI supports project, field, item, and field-value automation. View creation is intentionally documented rather than falsely automated because public CLI support for creating and configuring views is not equivalent to field automation.
