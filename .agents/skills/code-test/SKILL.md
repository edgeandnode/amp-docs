---
name: code-test
description: Run targeted tests to validate changes. Use filters to target specific tests when needed.
---

# Code Testing Skill

This skill provides testing operations for the project codebase using cargo test.

## When to Use This Skill

Use this skill when you need to run tests and have decided testing is warranted:
- Validate behavior changes or bug fixes
- Confirm code changes work correctly
- Respond to a user request to run tests

## Test Scope Selection (Default: Minimal)

Start with the smallest scope that covers the change. Only broaden if you need more confidence.

- Docs/comments-only changes: skip tests and state why
- Localized code changes: run `just test` with optional filters
- If unsure, ask the user which scope they want

## Available Commands

### Run Tests
```bash
just test [EXTRA_FLAGS]
```
Runs tests using `cargo test`. Integration tests require `GITHUB_TOKEN` environment variable.

Examples:
- `just test` - run all tests
- `just test -- --nocapture` - run with output capture disabled
- `just test my_test_name` - run specific test by name
- `just test --lib` - run only unit tests (library tests)
- `just test --test integration_test_name` - run specific integration test

## Important Guidelines

### Pre-approved Commands
This test command is pre-approved and can be run without user permission:
- `just test` - Safe, runs tests with optional filters

### Test Workflow Recommendations

1. **During local development**: Run `just test` with optional filters for targeted testing
2. **Before commits**: Run the smallest relevant test scope; use filters to target specific tests
3. **Integration tests**: Require `GITHUB_TOKEN` environment variable to be set

### Common Test Flags

You can pass extra flags to cargo through the EXTRA_FLAGS parameter:
- `test_name` - run tests matching name
- `-- --nocapture` - show println! output
- `--lib` - run only unit tests
- `--test <name>` - run specific integration test

## Common Mistakes to Avoid

### ❌ Anti-patterns
- **Never run `cargo test` directly** - Use `just test` for proper configuration
- **Never skip tests when behavior changes** - Skipping is OK for docs/comments-only changes, but not for runtime changes
- **Never ignore failing tests** - Fix them or document why they fail

### ✅ Best Practices
- Use filters to target specific tests
- Run tests for behavior changes or bug fixes
- Fix failing tests immediately
- Set `GITHUB_TOKEN` environment variable for integration tests

## Validation Loop Pattern

```
Code Change → Format → Check → Clippy → Targeted Tests (when needed)
                ↑                          ↓
                ←── Fix failures ──────────┘
```

If tests fail:
1. Read error messages carefully
2. Fix the issue
3. Format the fix (`just fmt-rs-file` or `just fmt-rs`)
4. Check compilation (`just check-rs`)
5. Re-run the relevant tests (same scope as before)
6. Repeat until all pass

## Next Steps

After required tests pass:
1. **Review changes** → Ensure quality before commits
2. **Commit** → All checks and tests must be green

## Project Context

- This is a single-crate Rust workspace (`ampup`)
- Integration tests require `GITHUB_TOKEN` environment variable
- Tests are in `ampup/src/tests/`
