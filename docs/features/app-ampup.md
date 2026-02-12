---
name: "app-ampup"
description: "Version manager and installer for amp project components. Load when asking about ampup, version management, installation, or building from source"
type: feature
status: experimental
components: "app:ampup"
---

# ampup - Version Manager & Installer

## Summary

ampup is the official version manager and installer for Amp binaries (ampd and ampctl), similar to rustup or nvm. It manages downloading pre-built binaries from GitHub releases, installing multiple versions side-by-side, switching between versions via symlinks, building from source (branch, commit, PR, or local path), and self-updating.

## Table of Contents

1. [Key Concepts](#key-concepts)
2. [Usage](#usage)
3. [Architecture](#architecture)
4. [Configuration](#configuration)

## Key Concepts

- **Version Manager**: Manages multiple installed versions of ampd/ampctl with symlink-based activation
- **Installer**: Downloads pre-built binaries from GitHub releases and extracts to versioned directories
- **Builder**: Compiles ampd/ampctl from source using cargo, supporting branch, commit, PR, or local path builds
- **Self-updater**: Atomic in-place binary replacement for updating ampup itself to the latest version
- **Active Version**: The currently selected version, tracked via symlinks in `~/.amp/bin/` and `.version` file

## Usage

### Installation

Install ampup using the shell installer:

```bash
curl -sSf https://ampup.sh/install | sh
```

The installer downloads the appropriate binary for your platform, runs `ampup init` to set up directories and PATH, and installs the latest ampd/ampctl version.

### Install a Specific Version

```bash
# Install latest version
ampup install

# Install specific version
ampup install v0.1.0

# Install with custom directory
ampup install --install-dir ~/.custom/amp v0.2.0
```

### List Installed Versions

```bash
ampup list
```

Shows all installed versions with an indicator for the currently active version.

### Switch Versions

```bash
# Interactive selection
ampup use

# Switch to specific version
ampup use v0.1.0
```

Switches the active version by updating symlinks in `~/.amp/bin/` and the `.version` file.

### Uninstall a Version

```bash
ampup uninstall v0.1.0
```

Removes the version directory. If uninstalling the active version, clears symlinks and `.version` file.

### Build from Source

```bash
# Build from default branch
ampup build

# Build from specific branch
ampup build --branch feature/new-thing

# Build from specific commit
ampup build --commit abc123

# Build from pull request
ampup build --pr 42

# Build from local path
ampup build --path ~/code/amp

# Build with custom version name
ampup build --branch develop --name my-dev-build

# Build with parallel jobs
ampup build --jobs 8
```

Clones the repository (or uses local path), runs `cargo build --release`, and installs the resulting binaries to `~/.amp/versions/<version>/`.

### Update to Latest

```bash
# Update ampd/ampctl to latest release
ampup update

# Equivalent to:
ampup install
```

### Self-Update

```bash
# Update ampup itself to latest version
ampup self update

# Print ampup version
ampup self version
```

The self-update performs atomic in-place replacement of the running executable.

## Architecture

### Directory Structure

```
~/.amp/                         # Base directory (configurable via AMP_DIR)
├── bin/                        # Symlinks to active version
│   ├── ampup                   # The ampup binary itself
│   ├── ampd -> ../versions/v0.1.0/ampd      # Symlink to active ampd
│   └── ampctl -> ../versions/v0.1.0/ampctl  # Symlink to active ampctl
├── versions/                   # All installed versions
│   ├── v0.1.0/
│   │   ├── ampd
│   │   └── ampctl
│   ├── v0.2.0/
│   │   ├── ampd
│   │   └── ampctl
│   └── my-dev-build/
│       ├── ampd
│       └── ampctl
└── .version                    # Tracks currently active version (e.g., "v0.1.0")
```

### Version Switching

1. User runs `ampup use <version>`
2. Verify version exists in `~/.amp/versions/<version>/`
3. Remove existing symlinks in `~/.amp/bin/`
4. Create new symlinks pointing to `~/.amp/versions/<version>/{ampd,ampctl}`
5. Write version string to `~/.amp/.version`

### Installation Flow

1. User runs `ampup install [version]`
2. Detect platform (Linux/Darwin) and architecture (x86_64/aarch64)
3. Query GitHub API for release (latest or specific tag)
4. Download artifact: `ampd-{platform}-{arch}`
5. Extract to `~/.amp/versions/<version>/`
6. Activate version (create symlinks)

### Build Flow

1. User runs `ampup build` with source specifier
2. Clone repository (or use local path)
3. Run `cargo build --release` in workspace
4. Extract version from `ampd --version` output
5. Copy `target/release/{ampd,ampctl}` to `~/.amp/versions/<version>/`
6. Activate version (create symlinks)

### Communication

```
ampup → GitHub Releases API      # Download pre-built binaries
ampup → GitHub API (tags, PRs)   # Fetch source for builds
ampup → ampup.sh/install         # Installation script download
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AMP_DIR` | `$XDG_CONFIG_HOME/.amp` or `$HOME/.amp` | Base installation directory |
| `GITHUB_TOKEN` | (none) | GitHub token for private repository access and API rate limits |
| `XDG_CONFIG_HOME` | `$HOME` | XDG base directory (fallback for `AMP_DIR`) |
| `SHELL` | (auto-detected) | Current shell for PATH modification (bash, zsh, fish, ash) |

### Shell Integration

ampup automatically adds `~/.amp/bin` to your PATH during `ampup init`:

| Shell | Profile File | Export Format |
|-------|--------------|---------------|
| bash | `~/.bashrc` | `export PATH="$PATH:~/.amp/bin"` |
| zsh | `$ZDOTDIR/.zshenv` or `~/.zshenv` | `export PATH="$PATH:~/.amp/bin"` |
| fish | `~/.config/fish/config.fish` | `fish_add_path -a ~/.amp/bin` |
| ash | `~/.profile` | `export PATH="$PATH:~/.amp/bin"` |

To skip PATH modification: `ampup init --no-modify-path`

### Platform Support

| Platform | Supported | Architecture |
|----------|-----------|--------------|
| Linux | ✓ | x86_64, aarch64 |
| macOS (Darwin) | ✓ | x86_64, aarch64 (Apple Silicon) |

Use `--platform` and `--arch` flags to override detection if needed.

### Command-Line Flags

All commands accept `--install-dir` to override the default installation directory:

```bash
ampup --install-dir /opt/amp install v0.1.0
ampup --install-dir /opt/amp list
```
