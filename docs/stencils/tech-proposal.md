# Tech Proposal Template

Copy the markdown below into `tech-proposals/NNNN-slug.md` on the `main` branch and fill it in.

**When to write one:** Any change that touches architecture, introduces a new dependency, or where multiple valid approaches exist. Must be approved before design work begins.

---

## Template

````markdown
---
id: PROP-NNNN
title: "Short title describing the problem"
status: DRAFT
author: ""
date: YYYY-MM-DD
---

# PROP-NNNN: Title

**Status:** DRAFT | **Author:** | **Date:**

---

## Problem

What is broken, missing, or suboptimal? Be specific.
Include user impact and technical context.

## Goals

- What must the solution achieve?

## Non-goals

- What is explicitly out of scope?

## Options

### Option A: Title

Description of the approach.

**Pros:**
-

**Cons:**
-

**Effort:** S / M / L

---

### Option B: Title

**Pros:**
-

**Cons:**
-

**Effort:** S / M / L

---

## Recommendation

**Chosen option:** Option X

Why this option over the others? State the key deciding factor.

## Open questions

- [ ] Question that must be resolved before this proposal is accepted.

## References

- Links to related issues, PRs, ADRs, or external docs.
````

---

## Status values

| Status | Meaning |
|---|---|
| `DRAFT` | Work in progress, not ready for review |
| `PROPOSED` | Ready for team review |
| `ACCEPTED` | Approved — tech spec can begin |
| `REJECTED` | Declined — reason documented in the proposal |
| `SUPERSEDED` | Replaced by a newer proposal |
