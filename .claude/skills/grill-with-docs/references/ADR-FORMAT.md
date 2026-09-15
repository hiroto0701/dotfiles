# ADR Format Overview

This guide establishes lightweight standards for Architecture Decision Records in `docs/adr/`.

## Key Structure

ADRs use sequential naming (`0001-slug.md`) and can be minimal—even a single paragraph suffices. The core value lies in documenting *that* a decision happened and *why*, not exhaustive documentation.

## Core Criteria

A decision warrants an ADR only when all three conditions apply:

1. **Hard to reverse** — meaningful cost to change later
2. **Non-obvious** — future readers will question the approach
3. **Result of trade-offs** — genuine alternatives existed

As the guide notes: "If a decision is easy to reverse, skip it. If it's not surprising, nobody will wonder why."

## What to Document

Strong candidates include:
- Architectural patterns (monorepos, event sourcing)
- Cross-service communication patterns
- High-switching-cost technology selections
- Explicit scope boundaries and ownership rules
- Deliberate departures from conventional approaches
- Non-code constraints (compliance, performance requirements)
- Subtle rejections of alternatives

## Optional Sections

Include Status (proposed/accepted/deprecated), Considered Options, or Consequences only when they meaningfully enhance understanding. Most ADRs won't need them.

## Example Format

```markdown
# 0001-domain-driven-design

We structure the codebase around domain boundaries (accounts, billing, reporting) rather than technical layers. This allows each domain to own its database schema and API contracts, reducing tight coupling.

We considered: single shared database, event-driven architecture.

**Trade-offs**: Domain ownership reduces coupling but increases operational complexity (multiple migrations, schema drift). Worth it given our three-team structure and independent release cycles.
```
