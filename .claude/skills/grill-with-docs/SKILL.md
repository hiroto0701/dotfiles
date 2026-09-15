---
name: grill-with-docs
description: Stress-test a plan against existing domain models and documentation. Use BEFORE /spec to validate that proposed architecture aligns with established terminology (CONTEXT.md), existing decisions (ADRs), and code patterns. Validates design edge cases, surfaces contradictions with existing glossaries, and updates documentation as decisions solidify. Replaces grill-me. Invoke when the user wants to "validate this against our domain model", "check terminology", "stress-test this plan", or mentions specific project context/constraints.
compatibility: Requires CONTEXT.md and/or docs/adr/ in the project. Gracefully skips documentation updates if not present.
---

# grill-with-docs: Stress-Test Plans Against Domain Models

## Core Purpose

This facilitation mode stress-tests architectural plans against existing domain models and documentation. It validates that your proposed solution:

- Uses correct terminology (CONTEXT.md)
- Aligns with prior decisions (ADRs)
- Handles edge cases consistently
- Doesn't contradict established patterns

## When to Use

Invoke this **after /brainstorm, before /spec** to ensure your initial concept is grounded in project reality.

### Typical triggers:
- "Check if this aligns with our domain model"
- "Validate this design against existing decisions"
- "Make sure I'm using the right terminology"
- "Stress-test this plan against [specific constraint]"

## How It Works

### 1. Codebase-First Exploration

Before asking you questions, I'll examine:
- `CONTEXT.md` — glossary of project-specific terminology
- `docs/adr/` — Architecture Decision Records
- Existing code patterns
- Prior decisions that might constrain your design

### 2. One-at-a-Time Questioning

I'll ask questions one by one, waiting for your answer before proceeding. This keeps the conversation focused and lets me adjust based on your responses.

### 3. Terminology Enforcement

If your language conflicts with CONTEXT.md, I flag it immediately. Example:
- Your plan says "payment method" but CONTEXT.md defines "instrument"
- You describe a workflow differently than existing ADRs suggest

### 4. Scenario & Edge Case Testing

I'll ask "What happens if...?" questions to expose boundary ambiguities. For example:
- "What happens if the invoice is already issued?"
- "How does this interact with the multi-tenant constraint from ADR-0003?"

### 5. Documentation Updates

As decisions solidify, I update:
- **CONTEXT.md** — capture newly resolved terminology
- **docs/adr/** — create ADRs *only* when all three criteria apply:
  1. **Hard to reverse** — meaningful cost to change later
  2. **Non-obvious** — future readers will question the approach
  3. **Result of trade-offs** — genuine alternatives existed with clear tradeoffs

If CONTEXT.md or ADRs don't exist, I'll guide you through creating them.

## Documentation Formats

Refer to:
- `CONTEXT-FORMAT.md` — how to structure the glossary
- `ADR-FORMAT.md` — lightweight ADR standards

## Expected Output

By the end:
- ✅ Your plan is validated against existing domain models
- ✅ Terminology is aligned with CONTEXT.md
- ✅ Contradictions with prior decisions are surfaced
- ✅ Edge cases are identified
- ✅ CONTEXT.md and ADRs are updated (if applicable)
- ✅ You're ready to move to /spec with confidence

## Key Principles

1. **Domain first** — terminology and constraints from CONTEXT.md take precedence over general programming concepts
2. **Lean documentation** — document only decisions that are hard to reverse, non-obvious, or result from tradeoffs
3. **Project-specific only** — capture unique domain terms, not general programming concepts
4. **One question at a time** — clarity over speed
