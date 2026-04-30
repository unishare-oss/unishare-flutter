#!/usr/bin/env python3
"""Auto-generate index tables for tech-specs, tech-proposals, and decisions."""

import os
import re
import sys

DOCS_DIR = "docs"


def parse_file(filepath, filename):
    with open(filepath, encoding="utf-8") as f:
        content = f.read()

    fm = {}

    # Try YAML frontmatter first
    match = re.match(r"^---\n(.*?)\n---\n", content, re.DOTALL)
    if match:
        for line in match.group(1).splitlines():
            if ":" in line:
                k, _, v = line.partition(":")
                fm[k.strip()] = v.strip().strip('"')

    # Fall back to inline markdown fields
    def inline(key):
        m = re.search(rf"\*\*{key}:\*\*\s*(.+)", content)
        return m.group(1).strip() if m else "—"

    # ID: from frontmatter or filename prefix
    file_id = fm.get("id", re.match(r"^(\d+)", filename))
    if hasattr(file_id, "group"):
        file_id = file_id.group(1)

    # Title: from frontmatter or first H1
    title = fm.get("title")
    if not title:
        m = re.search(r"^#\s+(.+)", content, re.MULTILINE)
        title = m.group(1).strip() if m else filename.replace(".md", "")

    status = fm.get("status") or inline("Status")
    date = fm.get("date") or inline("Date")
    proposal = fm.get("proposal") or inline("Proposal")

    return {
        "id": file_id or filename.replace(".md", ""),
        "title": title,
        "status": status,
        "date": str(date),
        "proposal": proposal,
    }


def collect(folder):
    entries = []
    if not os.path.isdir(folder):
        return entries
    for fname in sorted(os.listdir(folder)):
        if fname == "index.md" or not fname.endswith(".md"):
            continue
        entries.append((fname, parse_file(os.path.join(folder, fname), fname)))
    return entries


def replace_table(index_path, header, rows, empty_row):
    with open(index_path, encoding="utf-8") as f:
        content = f.read()

    # Find the last markdown table in the file and replace it
    table_re = re.compile(r"(\|[^\n]+\|\n\|[-| :]+\|\n(?:\|[^\n]+\|\n)*)", re.MULTILINE)
    matches = list(table_re.finditer(content))
    if not matches:
        print(f"  WARNING: no table found in {index_path}", file=sys.stderr)
        return

    last = matches[-1]
    body = "\n".join(rows) if rows else empty_row
    new_table = header + "\n" + body + "\n"
    new_content = content[: last.start()] + new_table + content[last.end():]

    with open(index_path, "w", encoding="utf-8") as f:
        f.write(new_content)
    print(f"  Updated {index_path} ({len(rows)} entries)")


# --- Tech Proposals ---
entries = collect(os.path.join(DOCS_DIR, "tech-proposals"))
rows = [
    f"| [{e['id']}]({fname}) | {e['title']} | {e['status']} | {e['date']} |"
    for fname, e in entries
]
replace_table(
    os.path.join(DOCS_DIR, "tech-proposals", "index.md"),
    "| # | Title | Status | Date |\n|---|---|---|---|",
    rows,
    "| — | No proposals yet | — | — |",
)

# --- Tech Specs ---
entries = collect(os.path.join(DOCS_DIR, "tech-specs"))
rows = [
    f"| [{e['id']}]({fname}) | {e['title']} | {e['status']} | {e['proposal']} |"
    for fname, e in entries
]
replace_table(
    os.path.join(DOCS_DIR, "tech-specs", "index.md"),
    "| # | Title | Status | Proposal |\n|---|---|---|---|",
    rows,
    "| — | No specs yet | — | — |",
)

# --- Decisions ---
entries = collect(os.path.join(DOCS_DIR, "decisions"))
rows = [
    f"| [{e['id']}]({fname}) | {e['title']} | {e['status']} | {e['date']} |"
    for fname, e in entries
]
replace_table(
    os.path.join(DOCS_DIR, "decisions", "index.md"),
    "| ID | Title | Status | Date |\n|---|---|---|---|",
    rows,
    "| — | No decisions yet | — | — |",
)
