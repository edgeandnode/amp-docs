# ampup

The official version manager and installer for [Amp](https://github.com/edgeandnode/amp), a tool for building and managing blockchain datasets.

## Installation

### Quick Install

```sh
curl --proto '=https' --tlsv1.2 -sSf https://ampup.sh/install | sh
```

This will install `ampup` and the latest version of `ampd`. You may need to restart your terminal or run `source ~/.zshenv` (or your shell's equivalent) to update your PATH.

### Customizing Installation

The installer script accepts options to customize the installation process:

```sh
# Skip automatic PATH modification
curl ... | sh -s -- --no-modify-path

# Skip installing the latest ampd version
curl ... | sh -s -- --no-install-latest

# Use a custom installation directory
curl ... | sh -s -- --install-dir /custom/path

# Combine multiple options
curl ... | sh -s -- --no-modify-path --no-install-latest --install-dir ~/.custom/amp
```

**Available Options:**

- `--install-dir <DIR>`: Install to a custom directory (default: `$XDG_CONFIG_HOME/.amp` or `$HOME/.amp`)
- `--no-modify-path`: Don't automatically add `ampup` to your PATH
- `--no-install-latest`: Don't automatically install the latest `ampd` version

### Installation via Nix

> This will be supported once the source repository has been released

For Nix users, `ampd` is available as a flake:

```sh
# Run directly without installing
nix run github:edgeandnode/amp

# Install to your profile
nix profile install github:edgeandnode/amp

# Try it out temporarily
nix shell github:edgeandnode/amp -c ampd --version
```

Note: Nix handles version management, so `ampup` is not needed for Nix users.

## Usage

### Install Latest Version

```sh
ampup install
```

### Install Specific Version

```sh
ampup install v0.1.0
```

### List Installed Versions

```sh
ampup list
```

### Switch Between Versions

```sh
ampup use v0.1.0
```

### Uninstall a Version

```sh
ampup uninstall v0.1.0
```

### Build from Source

```sh
# Build from the default repository's main branch
ampup build

# Build from a specific branch
ampup build --branch main

# Build from a specific commit
ampup build --commit abc123

# Build from a Pull Request
ampup build --pr 123

# Build from a local repository
ampup build --path /path/to/amp

# Build from a custom repository
ampup build --repo username/fork

# Combine options (e.g., custom repo + branch)
ampup build --repo username/fork --branch develop

# Build with a custom version name
ampup build --path . --name my-custom-build

# Build with specific number of jobs
ampup build --branch main --jobs 8
```

### Update ampup Itself

```sh
ampup update
```

## How It Works

`ampup` is a Rust-based version manager with a minimal bootstrap script for installation.

### Installation Methods

1. **Precompiled Binaries** (default): Downloads signed binaries from [GitHub releases](https://github.com/edgeandnode/amp/releases)
2. **Build from Source**: Clones and compiles the repository using Cargo

### Directory Structure

```
~/.amp/
├── bin/
│   ├── ampup            # Version manager binary
│   └── ampd             # Symlink to active version
├── versions/
│   ├── v0.1.0/
│   │   └── ampd         # Binary for v0.1.0
│   └── v0.2.0/
│       └── ampd         # Binary for v0.2.0
└── .version             # Tracks active version
```

## Supported Platforms

- Linux (x86_64, aarch64)
- macOS (aarch64/Apple Silicon)

## Environment Variables

- `GITHUB_TOKEN`: GitHub personal access token for private repository access
- `AMP_REPO`: Override repository (default: `edgeandnode/amp`)
- `AMP_DIR`: Override installation directory (default: `$XDG_CONFIG_HOME/.amp` or `$HOME/.amp`)

## Security

- macOS binaries are code-signed and notarized
- Private repository access uses GitHub's OAuth token mechanism

## Development

### Prerequisites

- Rust toolchain (pinned via `rust-toolchain.toml`)
- [just](https://just.systems/) task runner (optional)

### Commands

```sh
just          # List all commands
just check    # cargo check
just fmt      # Format code (requires nightly)
just test     # Run tests
just clippy   # Lint
```

### Web Site

The ampup.sh web site lives in `web/`:

```sh
cd web
pnpm install
pnpm dev      # Development server
pnpm build    # Production build
```

## Troubleshooting

### Command not found: ampup

Make sure the `ampup` binary is in your PATH. You may need to restart your terminal or run:

```sh
source ~/.bashrc  # or ~/.zshenv for zsh, or ~/.config/fish/config.fish for fish
```

### Download failed

- Check your internet connection
- Verify the release exists on GitHub
- For private repos, ensure `GITHUB_TOKEN` is set correctly

### Building from source requires Rust

If you're building from source (using the `build` command), you need:

- Rust toolchain (install from https://rustup.rs)
- Git
- Build dependencies (see main project documentation)

## Uninstalling

To uninstall ampd and ampup, simply delete your `.amp` directory (default: `$XDG_CONFIG_HOME/.amp` or `$HOME/.amp`):

```sh
rm -rf ~/.amp # or $XDG_CONFIG_HOME/.amp
```

Then remove the PATH entry from your shell configuration file.
