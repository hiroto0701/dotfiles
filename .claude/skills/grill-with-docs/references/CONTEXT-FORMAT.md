# CONTEXT.md Format Guide

This document defines how to create `CONTEXT.md` files—structured glossaries that capture domain-specific terminology for a project.

## Key Principles

**Opinionated terminology**: Choose one canonical term per concept and list alternatives to avoid. For example, prefer "Invoice" over "Bill" or "payment request."

**Tight definitions**: "One or two sentences max. Define what it IS, not what it does."

**Project-specific only**: Exclude general programming concepts like timeouts or error types. Include only terms unique to your domain.

**Flag ambiguities explicitly**: When terms have multiple interpretations, document the resolution clearly.

## Structure

Single-context repos use one `CONTEXT.md` at the root. Multi-context repos use a `CONTEXT-MAP.md` listing all contexts, their locations, and relationships between them.

Each term includes:
- A concise definition
- An "_Avoid_" section listing synonyms to discourage
- Bold formatting to show relationships and cardinality

## Validation Check

Before adding a term, ask: *Is this concept unique to this project's context, or a general programming principle?* Only domain-specific terms belong.

## Example Structure

```markdown
# CONTEXT.md — Payment Processing Domain

## Invoice
A billing document issued to a customer, containing one or more line items and total amount due.

_Avoid:_ Bill, payment request, receipt

## Line Item
A single billable service or product within an **Invoice**.

_Avoid:_ charge, fee, entry

## Payment Method
The mechanism by which a customer settles an **Invoice** (credit card, ACH transfer, etc).

_Avoid:_ instrument, payment channel
```
