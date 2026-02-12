# AGENTS.md

This file provides guidance to coding agents when working with code in this repository.

## Project Summary

**ampup** is the official version manager and installer for Amp (a tool for building and managing blockchain datasets). It has two components:

1. **Rust crate** (`ampup/`) — The `ampup` binary, a CLI tool for installing, managing, and building `ampd` versions
2. **Web site** (`web/`) — The landing page and documentation site at ampup.sh, built with Astro/Starlight

## Quick Start

**If you're an AI agent working on this codebase, here's what you need to know immediately:**

1. **Use Skills for operations** → Invoke skills (`/code-format`, `/code-check`, `/code-test`, `/code-review`, `/feature-discovery`, `/feature-fmt-check`, `/feature-validate`) instead of running commands directly
2. **Skills wrap justfile tasks** → Skills provide the interface to `just` commands with proper guidance
3. **Follow the workflow** → Format → Check → Clippy → Targeted Tests (when needed)
4. **Fix ALL warnings** → Zero tolerance for clippy warnings
5. **Check patterns** → Use `/code-pattern-discovery` before implementing code

**Your first action**: If you need to run a command, invoke the relevant Skill! If you need to implement code, invoke
`/code-pattern-discovery` to load relevant patterns!

**Testing default**: Run the smallest relevant test slice. Only broaden to `just test` for cross-cutting/high-risk changes or when you need broader confidence.

## Table of Contents

1. [Feature Discovery](#1-feature-discovery) - Understanding project features via `/feature-discovery` skill
2. [Coding Patterns](#2-coding-patterns) - Understanding coding standards via `/code-pattern-discovery` skill
3. [Development Workflow](#3-development-workflow) - How to develop with this codebase
4. [Additional Resources](#4-additional-resources) - Links to documentation

## 1. Feature Discovery

Feature documentation lives in `docs/features/` with YAML frontmatter for dynamic discovery.

**Feature docs are authoritative**: If a feature doc exists, it is the ground truth. Implementation MUST align with documentation. If there's a mismatch, either fix the code or update the doc to reflect the correct state.

| When User Asks                                              | Invoke This Skill    |
|-------------------------------------------------------------|----------------------|
| "What is X?", "How does X work?", "Explain the Y feature"   | `/feature-discovery` |
| "What features does ampup have?", "What can this project do?" | `/feature-discovery` |
| Questions about project functionality or capabilities       | `/feature-discovery` |
| Need context before implementing a feature                  | `/feature-discovery` |
| Creating or editing files in `docs/features/`               | `/feature-fmt-check` |
| Reviewing PRs that modify feature docs (format check)       | `/feature-fmt-check` |
| "What's the status of feature X implementation?"            | `/feature-validate`  |
| Verify feature doc matches implementation                   | `/feature-validate`  |
| Check if documented functionality exists in code            | `/feature-validate`  |
| Audit feature docs for accuracy and test coverage           | `/feature-validate`  |

**Navigation:**

- Need to understand a feature? → `/feature-discovery`
- Writing feature docs? → `/feature-fmt-check` + [docs/__meta__/feature-docs.md](docs/__meta__/feature-docs.md)
- Validate implementation aligns with feature claims? → `/feature-validate`


## 2. Coding Patterns

Coding pattern documentation lives in `docs/code/` with YAML frontmatter for dynamic discovery.

**Pattern docs are authoritative**: Pattern docs define how code should be written. All implementations MUST follow the patterns. If code doesn't follow a pattern, either fix the code or update the pattern (with team approval).

### Pattern Types

| Type               | Scope          | Purpose                                                       |
|--------------------|----------------|---------------------------------------------------------------|
| **Core**           | `global`       | Fundamental coding standards (error handling, modules, types) |
| **Architectural**  | `global`       | High-level patterns (crate structure, CLI design)             |
| **Crate-specific** | `crate:<name>` | Patterns for specific crates                                  |
| **Meta**           | `global`       | Documentation format specifications                           |

### Skill Invocation

| When You Need To                                              | Invoke This Skill         |
|---------------------------------------------------------------|---------------------------|
| Understand coding patterns before implementing                | `/code-pattern-discovery` |
| "How should I handle errors?", "What's the pattern for X?"    | `/code-pattern-discovery` |
| Load crate-specific patterns for ampup                        | `/code-pattern-discovery` |
| Creating or editing files in `docs/code/`                     | `/code-pattern-fmt-check` |
| Reviewing PRs that modify pattern docs                        | `/code-pattern-fmt-check` |

**Navigation:**

- Need to understand patterns? → `/code-pattern-discovery`
- Writing pattern docs? → `/code-pattern-fmt-check` + [docs/__meta__/code-pattern-docs.md](docs/__meta__/code-pattern-docs.md)
- All patterns located in `docs/code/`


## 3. Development Workflow

**This section provides guidance for AI agents on how to develop with this codebase.**

### Documentation Structure: Separation of Concerns

This project uses three complementary documentation systems. Understanding their roles helps AI agents navigate efficiently:

| Documentation                  | Purpose                  | Content Focus                                                                                                                                                                |
|--------------------------------|--------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **AGENTS.md** (this file)      | **WHY** and **WHAT**     | Project architecture, policies, goals, and principles. Answers "What is this project?" and "Why do we do things this way?"                                                   |
| **Skills** (`.agents/skills/`) | **HOW** and **WHEN**     | Command-line operations and justfile usage. Answers "How do I run commands?" and "When should I use each command?"                                                           |
| **Patterns** (`docs/code/`)    | **HOW** (implementation) | Code implementation patterns, standards, and guidelines (see [Coding Patterns](#2-coding-patterns)). Answers "How do I write quality code that follows project conventions?" |

**Navigation Guide for AI Agents:**

- Need to understand the project? → Read this file (AGENTS.md)
- Need to run a command? → Invoke the appropriate Skill (`/code-format`, `/code-check`, `/code-test`, `/code-review`)
- Need to write code? → Use `/code-pattern-discovery` skill to load relevant patterns

### Core Operating Principle

**MANDATORY: USE Skills for all common operations. Skills wrap justfile tasks with proper guidance.**

#### The Golden Rule

**USE Skills (`/code-format`, `/code-check`, `/code-test`, `/code-review`) for all common operations. Only use `cargo`, `pnpm`, or other tools directly when the operation is NOT covered by a skill or NOT available in the justfile.**

**Decision process:**

1. **First**: Check if a skill exists for your operation
2. **If exists**: Invoke the skill (provides proper flags, setup, and error handling)
3. **If not exists**: You may run the tool directly (e.g., `cargo run`, `cargo build`, tool-specific commands)

#### Why Skills Are Preferred

- **Consistency**: Uniform command execution across all developers and AI agents
- **Correctness**: Skills ensure proper flags, setup, and error handling
- **Guidance**: Skills provide context on when and how to use commands
- **Pre-approved workflows**: Skills document which commands can run without user permission

#### Examples

- ✅ **Use skill**: `/code-format` skill (formatting)
- ✅ **Use skill**: `/code-check` skill (checking and linting)
- ✅ **Use skill**: `/code-test` skill (testing)
- ✅ **Use skill**: `/code-review` skill (code review)
- ✅ **Direct tool OK**: `cargo run -p ampup -- install --help` (running binaries not in justfile)
- ✅ **Direct tool OK**: `cargo build --release` (release builds not in justfile's check task)
- ✅ **Direct tool OK**: Tool-specific commands not covered by justfile tasks

#### Command Execution Hierarchy (Priority Order)

When determining which command to run, follow this strict hierarchy:

1. **Priority 1: Skills** (`.agents/skills/`)
   - Skills are the **SINGLE SOURCE OF TRUTH** for all command execution
   - If Skills document a command, use it EXACTLY as shown
   - Skills override any other guidance in AGENTS.md or elsewhere

2. **Priority 2: AGENTS.md workflow**
   - High-level workflow guidance (when to format, check, test)
   - Refers you to Skills for specific commands

3. **Priority 3: Everything else**
   - Other documentation is supplementary
   - When in conflict, Skills always win

#### Workflow Gate: Use Skills First

**Before running ANY command:**

1. Ask yourself: "Which Skill covers this operation?"
2. Invoke the appropriate skill (e.g., `/code-format`, `/code-check`, `/code-test`, `/code-review`)
3. Let the skill guide you through the operation

**Example decision tree:**

- Need to format a file? → Use `/code-format` skill
- Need to check a crate? → Use `/code-check` skill
- Need to run tests? → Use `/code-test` skill (choose the smallest relevant scope)

### Command-Line Operations Reference

**CRITICAL: Use skills for all operations - invoke them before running commands.**

Available skills and their purposes:

- **Formatting**: Use `/code-format` skill - Format code after editing files
- **Checking/Linting**: Use `/code-check` skill - Validate and lint code changes
- **Testing**: Use `/code-test` skill - Run targeted tests when warranted
- **Code Review**: Use `/code-review` skill - Review code changes for quality

Each Skill provides:

- ✅ **When to use** - Clear guidance on appropriate usage
- ✅ **Available operations** - All supported tasks with proper execution
- ✅ **Examples** - Real-world usage patterns
- ✅ **Pre-approved workflows** - Operations that can run without user permission
- ✅ **Workflow integration** - How operations fit into development flow

**Remember: If you don't know which operation to perform, invoke the appropriate Skill.**

### Pre-Implementation Checklist

**BEFORE writing ANY code, you MUST:**

1. **Understand the task** - Research the codebase and identify affected module(s)
2. **Load implementation patterns** - Use `/code-pattern-discovery` skill (see [Coding Patterns](#2-coding-patterns))
3. **Follow crate-specific patterns** - Pattern discovery loads crate-specific and security patterns automatically

### Typical Development Workflow

**Follow this workflow when implementing features or fixing bugs:**

#### 1. Research Phase

- Understand the codebase and existing patterns
- Identify related modules and dependencies
- Review test files and usage examples
- Use `/code-pattern-discovery` to load relevant implementation patterns

#### 2. Planning Phase

- **First**: Use `/code-pattern-discovery` to load relevant patterns for the affected module(s)
- Create detailed implementation plan based on the loaded patterns
- Ensure plan follows required patterns (error handling, type design, module structure, etc.)
- Identify validation checkpoints
- Consider edge cases and error handling according to pattern guidelines
- Ask user questions if requirements are unclear

#### 3. Implementation Phase

**CRITICAL: Before running ANY command in this phase, invoke the relevant Skill.**

**Copy this checklist and track your progress:**

```
Development Progress:
- [ ] Step 1: Write code following patterns from Coding Patterns section (use /code-pattern-discovery)
- [ ] Step 2: Format code (use /code-format skill)
- [ ] Step 3: Check compilation (use /code-check skill)
- [ ] Step 4: Fix all compilation errors
- [ ] Step 5: Run clippy (use /code-check skill)
- [ ] Step 6: Fix ALL clippy warnings
- [ ] Step 7: Run targeted tests when warranted (use /code-test skill)
- [ ] Step 8: Fix test failures or document why tests were skipped
- [ ] Step 9: All required checks pass ✅
```

**Detailed workflow for each work chunk (and before committing):**

1. **Write code** following patterns from [Coding Patterns](#2-coding-patterns) (loaded via `/code-pattern-discovery`)

2. **Format before checks/commit**:
   - **Use**: `/code-format` skill when you finish a coherent chunk of work
   - **Validation**: Verify no formatting changes remain

3. **Check compilation**:
   - **Use**: `/code-check` skill after changes
   - **Must pass**: Fix all compilation errors
   - **Validation**: Ensure zero errors before proceeding

4. **Lint with clippy**:
   - **Use**: `/code-check` skill for linting
   - **Must pass**: Fix all clippy warnings
   - **Validation**: Re-run until zero warnings before proceeding

5. **Run targeted tests (when warranted)**:
   - **Use**: `/code-test` skill to select the smallest relevant scope
   - **Escalate**: Use `just test` only for cross-cutting/high-risk changes or when broader confidence is needed
   - **Validation**: Fix failures or record why tests were skipped

6. **Iterate**: If any validation fails → fix → return to step 2

**Visual Workflow:**

```
Edit File → /code-format skill
          ↓
    /code-check skill (compile) → Fix errors?
          ↓                            ↓ Yes
    /code-check skill (clippy) → (loop back)
          ↓
    Targeted tests (if needed) → Fix failures?
          ↓                 ↓ Yes
    All Pass ✅      (loop back)
```

**Remember**: Invoke Skills for all operations. If unsure which skill to use, refer to the Command-Line Operations Reference above.

#### 4. Completion Phase

- Ensure all required checks pass (format, check, clippy, and any tests you ran)
- If tests were skipped, document why and the risk assessment
- Review changes against patterns and security guidelines
- Document any warnings you couldn't fix and why

### Core Development Principles

**ALL AI agents MUST follow these principles:**

- **Research → Plan → Implement**: Never jump straight to coding
- **Pattern compliance**: Follow patterns from [Coding Patterns](#2-coding-patterns)
- **Zero tolerance for errors**: All automated checks must pass
- **Clarity over cleverness**: Choose clear, maintainable solutions
- **Security first**: Never skip security guidelines

**Essential conventions:**

- **Never expose secrets/keys**: All sensitive data in environment variables
- **Maintain type safety**: Leverage Rust's type system fully
- **Prefer async operations**: This codebase uses async/await extensively
- **Run targeted tests when warranted**: Use `/code-test` skill and broaden only if necessary
- **Format code before checks/commit**: Use `/code-format` skill
- **Fix all warnings**: Use `/code-check` skill for clippy

### Summary: Key Takeaways for AI Agents

**You've learned the complete workflow. Here's what to remember:**

| What             | Where                                 | When                                |
|------------------|---------------------------------------|-------------------------------------|
| **Plan work**    | `/code-pattern-discovery`             | BEFORE creating any plan            |
| **Run commands** | `.agents/skills/`                     | Check Skills BEFORE any command     |
| **Write code**   | [Coding Patterns](#2-coding-patterns) | Load patterns before implementation |
| **Format**       | `/code-format`                        | Before checks or before committing  |
| **Check**        | `/code-check`                         | After formatting                    |
| **Lint**         | `/code-check`                         | Fix ALL warnings                    |
| **Test**         | `/code-test`                          | Validate changes with targeted tests when warranted |

**Golden Rules:**

1. ✅ Invoke Skills for all common operations
2. ✅ Skills wrap justfile tasks with proper guidance
3. ✅ Follow the workflow: Format → Check → Clippy → Targeted Tests (when needed)
4. ✅ Zero tolerance for errors and warnings
5. ✅ Every change improves the codebase

**Remember**: When in doubt, invoke the appropriate Skill!

## 4. Additional Resources

For more detailed information about the project:

### Architecture

#### Rust Crate

- **Entry point**: `ampup/src/main.rs` — CLI definition with clap
- **Library**: `ampup/src/lib.rs` — exposes all modules
- **Commands**: `ampup/src/commands/` — install, list, use, uninstall, build, update, init (hidden, called by install script), self (subcommands: update, version)
- **Core modules**:
  - `ampup/src/github.rs` — GitHub API client for releases
  - `ampup/src/version_manager.rs` — version installation/activation management
  - `ampup/src/install.rs` — binary download and installation logic
  - `ampup/src/builder.rs` — build-from-source functionality
  - `ampup/src/config.rs` — configuration and directory management
  - `ampup/src/platform.rs` — platform/architecture detection
  - `ampup/src/shell.rs` — shell detection and PATH modification
  - `ampup/src/updater.rs` — self-update functionality
  - `ampup/src/ui.rs` — UI macros and formatting
- **Tests**: `ampup/src/tests/` — integration tests with fixtures
- **Build script**: `ampup/build.rs` — vergen-gitcl for build metadata

#### Web Site

- **Framework**: Astro static site with Starlight documentation
- **Landing Page**: `web/src/pages/index.astro` — main landing page at `/`
- **Documentation**: Powered by Astro Starlight at `/docs`
  - Content in `web/src/content/docs/`
  - Configured in `web/astro.config.ts` with `@astrojs/starlight` integration
  - Content collections configured in `web/src/content.config.ts`
- **Installer**: `web/public/install` → symlink to `../../install` (root-level install script)
  - Shell script that downloads and installs ampup binary
  - Detects platform (Linux/Darwin) and architecture (x86_64/aarch64)
  - Downloads from GitHub releases: `github.com/edgeandnode/amp/releases/latest`
  - Served at `https://ampup.sh/install`

### Key Files

- `Cargo.toml` — Workspace manifest
- `ampup/Cargo.toml` — Rust crate manifest
- `ampup/build.rs` — Build script for version metadata
- `rust-toolchain.toml` — Pins Rust 1.92.0
- `rustfmt.toml` — Formatting config (nightly features)
- `justfile` — Task runner commands
- `install` — Platform-agnostic installer script (root level)
- `web/package.json` — Web site dependencies
- `web/astro.config.ts` — Astro configuration
- `web/public/install` — Symlink to `../../install`

### Documentation

- `docs/features/` — Feature documentation
- `docs/code/` — Code pattern documentation
- `docs/__meta__/` — Documentation format specifications
- `web/src/content/docs/` — User-facing documentation served at `/docs`

### Agent Configuration

This repository includes agent-specific configuration and skills:

- `.agents/skills/` — 11 skills for agent workflows:
  - `code-format`, `code-check`, `code-review`, `code-test` — code quality automation
  - `code-pattern-discovery`, `code-pattern-fmt-check` — pattern documentation
  - `feature-discovery`, `feature-status`, `feature-validate`, `feature-fmt-check` — feature documentation
  - `commit` — conventional commit message generation with Rust workspace scope rules
- `CLAUDE.md` → symlink to `AGENTS.md` (this file)
- `.agents/` → symlink to `.agents/`

### Package Manager

Use `pnpm` for all web package management operations (specified in `web/package.json` packageManager field).
