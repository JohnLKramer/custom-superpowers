# CSV Importer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development.

**Goal:** Import customer CSVs into SQLite with validation and a CLI.
**Spec:** docs/specs/csv-importer.md

## Global Constraints
- Python 3.11, no third-party deps except pytest.
- Max row size 64 KiB; reject larger rows with ImportError("row too large").


### Task 1: Row model
Files: src/importer/row.py, tests/test_row.py. Produces: `Row(fields: dict[str,str])`.
(steps: failing test, implement, pass, commit)

### Task 2: CSV reader
Files: src/importer/reader.py, tests/test_reader.py. Consumes Row. Produces `read_rows(path) -> Iterator[Row]`.

### Task 3: Row validation
Files: src/importer/validate.py, tests/test_validate.py. Produces `validate(row) -> list[str]`.


### Task 4: SQLite writer
Files: src/importer/store.py, tests/test_store.py. Produces `write(rows, db_path) -> int`.

### Task 5: CLI entrypoint
Files: src/importer/cli.py, tests/test_cli.py. Consumes read_rows, validate, write.

### Task 6: README usage section
Files: README.md.
