# ADR Template

Copy the markdown below into `docs/decisions/NNNN-slug.md` on the `main` branch and fill it in.

**When to write one:** After any non-trivial architectural decision is made. ADRs are immutable — never edit a published one, write a new one that supersedes it instead.

---

## Template

````markdown
---
title: "NNNN: Short present-tense statement of the decision"
description: "One-line summary of the decision and its context."
---

# NNNN — Title

**Status:** PROPOSED  
**Author:**  
**Date:** YYYY-MM-DD

## Problem

State the problem in one paragraph. What constraint or requirement forced a decision?

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | | | |
| 2 | | | |
| 3 | | | |

## Decision

**Chosen:** Option N — [name]

3-sentence justification: what it does, why it fits better than the alternatives, what assumption it relies on.

## Reversal Cost

Low / Medium / High — what would it take to undo this decision?

## Consequences

What becomes easier? What becomes harder? Any follow-up decisions required?
````

---

## Status values

| Status | Meaning |
|---|---|
| `PROPOSED` | Under discussion |
| `ACCEPTED` | Decision is in effect |
| `SUPERSEDED by #NNNN` | Replaced — link to the new ADR |
