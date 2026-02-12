---
name: code-format
description: Format Rust and shell script code automatically. Use immediately after editing .rs/.sh files or the install script, when user mentions formatting, code style, or before commits/PRs. Ensures consistent code style following project conventions.
---

# Code Formatting Skill

This skill provides code formatting operations for the project codebase, which is a single-crate Rust workspace with shell scripts.

## When to Use This Skill

Use this skill when you need to:
- Format code after editing Rust or shell script files
- Format the `install` script after making changes
- Check if code meets formatting standards
- Ensure code formatting compliance before commits

## Command Selection Rules

Choose the appropriate command based on the number of files edited:

| Files Edited | File Type  | Command to Use | Rationale |
|--------------|------------|----------------|-----------|
| 1-2 files    | Rust       | `just fmt-rs-file <file>` (per file) | Faster, targeted formatting |
| 3+ files     | Rust       | `just fmt-rs` (global) | More efficient than multiple per-file calls |
| Any          | Shell      | `just fmt-sh` | Formats the `install` script |

**Decision process:**
1. Count the number of files you edited (by type: Rust or Shell)
2. If 2 or fewer Rust files: run `just fmt-rs-file` for each file
3. If 3 or more Rust files: run the global command `just fmt-rs`
4. For shell scripts: always run `just fmt-sh` (currently only formats the `install` script)

## Available Commands

### Format Rust Code
```bash
just fmt-rs
```
Formats all Rust code using `cargo +nightly fmt --all`. This is the primary formatting command.

**Alias**: `just fmt` (same as `fmt-rs`)

### Check Rust Formatting
```bash
just fmt-rs-check
```
Checks Rust code formatting without making changes using `cargo +nightly fmt --all -- --check`.

**Alias**: `just fmt-check` (same as `fmt-rs-check`)

### Format Specific Rust File
```bash
just fmt-rs-file <FILE>
```
Formats a specific Rust file using `cargo +nightly fmt`.

Examples:
- `just fmt-rs-file ampup/src/main.rs` - formats a Rust file
- `just fmt-rs-file ampup/src/config.rs` - formats another Rust file

### Format Shell Scripts
```bash
just fmt-sh
```
Formats shell scripts. Currently formats the `install` script.

**Requirements**: Requires `shfmt` to be installed. The command will provide installation instructions if not available.

### Check Shell Script Formatting
```bash
just fmt-sh-check
```
Checks shell script formatting without making changes.

## Important Guidelines

### Format Before Checks/Commit
Format code when you finish a coherent chunk of work and before running checks or committing.

This is a critical requirement from the project's development workflow:
- Do not skip formatting before checks/commit
- Use the Command Selection Rules above to choose the right command
- Run formatting before any check or test commands

### Example Workflows

**Single file edit:**
1. Edit a Rust file: `ampup/src/config.rs`
2. When ready to validate, run: `just fmt-rs-file ampup/src/config.rs`
3. Then run checks

**Multiple files edit (3+):**
1. Edit multiple Rust files across the codebase
2. When ready to validate, run: `just fmt-rs`
3. Then run checks

**Shell script edit:**
1. Edit the `install` script
2. When ready to validate, run: `just fmt-sh`
3. Then run checks

## Common Mistakes to Avoid

### ❌ Anti-patterns
- **Never run `cargo fmt` directly** - Use `just fmt-rs-file` or `just fmt-rs`
- **Never run `rustfmt` directly** - The justfile includes proper flags
- **Never run `shfmt` directly** - Use `just fmt-sh`
- **Never skip formatting before checks/commit** - Even "minor" edits need formatting
- **Never use `just fmt-rs` for 1-2 files** - Use `just fmt-rs-file <file>` for efficiency
- **Never use `just fmt-rs-file` for 3+ files** - Use `just fmt-rs` for efficiency

### ✅ Best Practices
- Format before running checks/tests or before committing
- Use `just fmt-rs-file` for 1-2 files (faster, targeted)
- Use `just fmt-rs` for 3+ files (more efficient)
- Use `just fmt-sh` after editing the `install` script
- Run format check commands to verify formatting before commits

## Next Steps

After formatting your code:
1. **Check compilation** → See `.agents/skills/code-check/SKILL.md`
2. **Run clippy** → See `.agents/skills/code-check/SKILL.md`
3. **Run targeted tests when warranted** → See `.agents/skills/code-test/SKILL.md`
