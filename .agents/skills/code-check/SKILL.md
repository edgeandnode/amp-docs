---
name: code-check
description: Validate and lint code after changes. Use after editing Rust/shell script files, when user mentions compilation errors, linting, clippy warnings, shellcheck issues, or before commits/PRs. Ensures all code passes checks and has zero warnings.
---

# Code Checking Skill

This skill provides code validation and linting operations for the project codebase, which is a single-crate Rust workspace.

## When to Use This Skill

Use this skill when you need to:
- Validate Rust or shell script code after making changes
- Run compiler checks without building
- Lint code with clippy (Rust) or shellcheck (shell scripts)
- Ensure code quality before commits or PRs

## Available Commands

### Check Rust Code
```bash
just check-rs [EXTRA_FLAGS]
```
Checks Rust code using `cargo check --all-targets`. This runs the compiler without producing binaries.

**Alias**: `just check` (same as `check-rs`)

Examples:
- `just check-rs` - check all Rust code
- `just check-rs --release` - check with release optimizations

### Lint Rust Code (Clippy)
```bash
just clippy [EXTRA_FLAGS]
```
Lints all Rust code using `cargo clippy --all-targets`. Clippy catches common mistakes and suggests improvements.

Examples:
- `just clippy` - lint all code
- `just clippy -- -D warnings` - treat warnings as errors

### Check Shell Scripts
```bash
just check-sh
```
Lints shell scripts. Currently checks the `install` script.

**Requirements**: Requires `shellcheck` to be installed. The command will provide installation instructions if not available.

## Important Guidelines

### MANDATORY: Run Checks After Changes
**You MUST run checks after making code changes. Use the Command Selection Rules above to choose the right command.**

Before considering a task complete: all checks MUST pass AND all clippy warnings MUST be fixed.

### Example Workflows

**Rust code:**
1. Edit files in the `ampup` crate
2. Format: use `/code-format` skill
3. **Check compilation**: `just check-rs`
   - If errors → fix → return to step 2
4. **Check clippy**: `just clippy`
   - If warnings → fix ALL → return to step 2
5. Repeat until: zero compilation errors AND zero clippy warnings

**Shell script (install script):**
1. Edit the `install` script
2. Format: use `/code-format` skill (run `just fmt-sh`)
3. **Check shellcheck**: `just check-sh`
   - If warnings → fix ALL → return to step 2
4. Repeat until: zero shellcheck warnings

## Common Mistakes to Avoid

### ❌ Anti-patterns
- **Never run `cargo check` directly** - Use `just check-rs`
- **Never run `cargo clippy` directly** - Justfile adds proper flags
- **Never run `shellcheck` directly** - Use `just check-sh`
- **Never ignore clippy warnings** - Clippy is enforced in CI, warnings will fail builds
- **Never ignore shellcheck warnings** - Shell scripts must pass shellcheck
- **Never skip the check step** - Even if "it should compile" or "the script works"

### ✅ Best Practices
- Use `just check-rs` for Rust compilation checks
- Use `just clippy` for Rust linting
- Use `just check-sh` after editing the `install` script
- Fix compilation errors before running clippy
- Run clippy when you finish a coherent chunk of work or before committing
- Document any warnings you absolutely cannot fix (rare exception)

## Pre-approved Commands
These commands can run without user permission:
- `just check-rs` - Safe, read-only compilation check
- `just clippy` - Safe, read-only linting
- `just check-sh` - Safe, read-only shell script linting

## Next Steps

After all checks pass:
1. **Run targeted tests when warranted** → See `.agents/skills/code-test/SKILL.md`
2. **Commit changes** → Ensure all checks green first
