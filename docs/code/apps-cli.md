---
name: "apps-cli"
description: "Patterns for CLI output formatting (UI macros, error handling, styling). Load when adding or updating CLI commands or output formatting."
type: core
scope: "global"
---

# CLI Output Patterns

## Purpose

This document establishes consistent CLI output patterns for the `ampup` binary.
These patterns ensure:

- **Consistent UX** - Uniform output styling across all commands
- **Clean stdout** - Results go to stdout, warnings/errors go to stderr
- **Terminal-friendly** - Styled output using colors, bold text, and icons
- **Predictable formatting** - All messages use UI macros, not direct `println!`

## Table of Contents

- [CLI Output Patterns](#cli-output-patterns)
  - [Purpose](#purpose)
  - [Table of Contents](#table-of-contents)
  - [Core Principles](#core-principles)
    - [1. UI Macros for Consistent Output](#1-ui-macros-for-consistent-output)
    - [2. Stdout for Results, Stderr for Errors/Warnings](#2-stdout-for-results-stderr-for-errorswarnings)
    - [3. Styled Terminal Output](#3-styled-terminal-output)
    - [4. No Direct `println!` for Messages](#4-no-direct-println-for-messages)
  - [UI Macro Reference](#ui-macro-reference)
    - [Macro Definitions](#macro-definitions)
    - [Styling Helpers](#styling-helpers)
  - [Error Output Pattern](#error-output-pattern)
    - [Top-Level Error Handler](#top-level-error-handler)
    - [Custom Error Types](#custom-error-types)
    - [Error Propagation](#error-propagation)
  - [Progress & Interactive UI](#progress--interactive-ui)
    - [Progress Bars](#progress-bars)
    - [Interactive Selection](#interactive-selection)
  - [Examples](#examples)
    - [Example: Install Command Output](#example-install-command-output)
    - [Example: Custom Error Type](#example-custom-error-type)
    - [Example: Interactive Selection](#example-interactive-selection)
  - [References](#references)
  - [Checklist](#checklist)

## Core Principles

### 1. UI Macros for Consistent Output

**REQUIRED**: All command output must use UI macros defined in `ampup/src/ui.rs`:

- `success!` - Success messages with green checkmark
- `info!` - Informational messages with cyan arrow
- `warn!` - Warning messages with yellow warning symbol
- `detail!` - Dimmed detail messages (indented)

### 2. Stdout for Results, Stderr for Errors/Warnings

**REQUIRED**: Results and informational messages go to **stdout** via `success!`, `info!`, and `detail!` macros. Warnings go to **stderr** via `warn!`. Errors are handled by the top-level error handler which outputs to **stderr**.

### 3. Styled Terminal Output

**REQUIRED**: All styled output uses the `console` crate for colors, bold text, and dimming. The UI macros and styling helpers provide consistent formatting.

### 4. No Direct `println!` for Messages

**REQUIRED**: Commands must not use raw `println!` or `eprintln!` for status messages. Use UI macros instead.

**Exceptions**: Direct `println!` is only acceptable for:
- `list` command - outputs version list with custom formatting
- `self version` command - outputs version string directly

## UI Macro Reference

### Macro Definitions

All macros are defined in `ampup/src/ui.rs`:

| Macro | Channel | Prefix | Style |
|-------|---------|--------|-------|
| `success!` | stdout | `✓` green bold | Normal |
| `info!` | stdout | `→` cyan | Normal |
| `warn!` | stderr | `⚠` yellow bold | Normal |
| `detail!` | stdout | 2-space indent | Dimmed |

**Usage examples**:

```rust
use crate::ui;

// Success message
ui::success!("Installed ampd and ampctl {}", ui::version(&version));

// Info message
ui::info!("Fetching latest version");

// Warning message
ui::warn!("Version {} is not installed", version);

// Detail message (indented, dimmed)
ui::detail!("Run 'ampd --version' to verify installation");
```

### Styling Helpers

**Defined in `ampup/src/ui.rs`**:

- `ui::version(v)` - Bold white version string
- `ui::path(p)` - Cyan path string

**Usage**:

```rust
ui::success!("Installed ampd {}", ui::version("v0.1.0"));
ui::info!("Installation directory: {}", ui::path("/home/user/.amp"));
```

## Error Output Pattern

### Top-Level Error Handler

**Location**: `ampup/src/main.rs`

The top-level error handler catches all errors and formats them with a red bold `✗` prefix to stderr:

```rust
#[tokio::main]
async fn main() {
    if let Err(e) = run().await {
        // Print the error with custom formatting
        eprintln!("{} {}", style("✗").red().bold(), e);
        std::process::exit(1);
    }
}
```

### Custom Error Types

**REQUIRED**: Complex error scenarios use custom error types with rich multi-line `Display` implementations.

**Pattern**:
- Define enum with error variants
- Implement `std::fmt::Display` with multi-line formatting (context, details, suggestions)
- Implement `std::error::Error` trait
- Convert to `anyhow::Error` via `.into()`

### Error Propagation

**REQUIRED**: Use `anyhow::Result` for all fallible functions and propagate errors with `.context()` for additional context:

```rust
use anyhow::{Context, Result};

pub fn activate(&self, version: &str) -> Result<()> {
    let version_dir = self.config.versions_dir.join(version);
    if !version_dir.exists() {
        return Err(VersionError::NotInstalled {
            version: version.to_string(),
        }
        .into());
    }

    fs::create_dir_all(&self.config.bin_dir)
        .context("Failed to create bin directory")?;

    Ok(())
}
```

## Progress & Interactive UI

### Progress Bars

**Library**: `indicatif`

**Usage**: For long-running operations like downloads, use `indicatif` progress bars.

**Example**: Download progress in `ampup/src/install.rs`

### Interactive Selection

**Library**: `dialoguer`

**Usage**: For interactive user prompts, use `dialoguer::Select` with `ColorfulTheme`.

**Example**: Version selection in `ampup/src/commands/use_version.rs`

## Examples

### Example: Install Command Output

**File**: `ampup/src/commands/install.rs`

```rust
use anyhow::Result;
use crate::ui;

pub async fn run(
    install_dir: Option<std::path::PathBuf>,
    repo: String,
    github_token: Option<String>,
    version: Option<String>,
    arch_override: Option<String>,
    platform_override: Option<String>,
) -> Result<()> {
    // Determine version to install
    let version = match version {
        Some(v) => v,
        None => {
            ui::info!("Fetching latest version");
            github.get_latest_version().await?
        }
    };

    // Check if version is already installed
    if version_manager.is_installed(&version) {
        ui::info!("Version {} is already installed", ui::version(&version));

        let current_version = version_manager.get_current()?;
        if current_version.as_deref() == Some(&version) {
            ui::success!("Already using version {}", ui::version(&version));
            return Ok(());
        }

        ui::info!("Switching to version {}", ui::version(&version));
        switch_to_version(&version_manager, &version)?;
        ui::success!("Switched to version {}", ui::version(&version));
        ui::detail!("Run 'ampd --version' and 'ampctl --version' to verify installation");
        return Ok(());
    }

    ui::info!("Installing version {}", ui::version(&version));
    ui::detail!("Platform: {}, Architecture: {}", platform, arch);

    // Install the binary
    installer.install_from_release(&version, platform, arch).await?;

    ui::success!("Installed ampd and ampctl {}", ui::version(&version));
    ui::detail!("Run 'ampd --version' and 'ampctl --version' to verify installation");

    Ok(())
}
```

### Example: Custom Error Type

**File**: `ampup/src/version_manager.rs`

```rust
/// Version management errors
#[derive(Debug)]
pub enum VersionError {
    NotInstalled { version: String },
    NoVersionsInstalled,
    BinaryNotFound { version: String },
}

impl std::fmt::Display for VersionError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::NotInstalled { version } => {
                writeln!(f, "Version not installed")?;
                writeln!(f, "  Version: {}", version)?;
                writeln!(f)?;
                writeln!(f, "  Try: ampup install {}", version)?;
            }
            Self::NoVersionsInstalled => {
                writeln!(f, "No versions installed")?;
                writeln!(f)?;
                writeln!(f, "  Try: ampup install")?;
            }
            Self::BinaryNotFound { version } => {
                writeln!(f, "Binary not found")?;
                writeln!(f, "  Version: {}", version)?;
                writeln!(f)?;
                writeln!(f, "  Installation may be corrupted.")?;
                writeln!(f, "  Try: ampup install {}", version)?;
            }
        }
        Ok(())
    }
}

impl std::error::Error for VersionError {}
```

### Example: Interactive Selection

**File**: `ampup/src/commands/use_version.rs`

```rust
use dialoguer::{Select, theme::ColorfulTheme};
use anyhow::{Context, Result};

fn select_version(version_manager: &VersionManager) -> Result<String> {
    let versions = version_manager.list_installed()?;

    if versions.is_empty() {
        return Err(VersionError::NoVersionsInstalled.into());
    }

    let current_version = version_manager.get_current()?;

    // Create display items with current indicator
    let display_items: Vec<String> = versions
        .iter()
        .map(|v| {
            if Some(v) == current_version.as_ref() {
                format!("{} (current)", v)
            } else {
                v.clone()
            }
        })
        .collect();

    // Find default selection (current version if exists)
    let default_index = current_version
        .as_ref()
        .and_then(|cv| versions.iter().position(|v| v == cv))
        .unwrap_or(0);

    // Show interactive selection
    let selection = Select::with_theme(&ColorfulTheme::default())
        .with_prompt("Select a version to use")
        .default(default_index)
        .items(&display_items)
        .interact()
        .context("Failed to get user selection")?;

    Ok(versions[selection].clone())
}
```

## References

**Foundation patterns**:
- [`errors-handling`](./errors-handling.md) - Error handling patterns and propagation
- [`errors-reporting`](./errors-reporting.md) - Error Display formatting and multi-line messages

**Related patterns**:
- [`rust-crate`](./rust-crate.md) - Crate structure and dependencies

## Checklist

- [ ] Command outputs results via UI macros (`success!`, `info!`, `detail!`)
- [ ] Warnings use `warn!` macro (outputs to stderr)
- [ ] No direct `println!`/`eprintln!` for status messages (except `list` and `self version`)
- [ ] Errors propagate via `anyhow::Result` with `.context()`
- [ ] Complex errors use custom error types with rich `Display` implementations
- [ ] Top-level error handler formats errors to stderr with red bold `✗` prefix
- [ ] Progress bars use `indicatif` for long operations
- [ ] Interactive prompts use `dialoguer` with `ColorfulTheme`
- [ ] Styling helpers used for versions (`ui::version`) and paths (`ui::path`)
