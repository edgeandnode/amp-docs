# Display available commands and their descriptions (default target)
default:
    @just --list


## Workspace management

alias clean := cargo-clean

# Clean cargo build artifacts (cargo clean)
[group: 'workspace']
cargo-clean:
    cargo clean


## Code formatting and linting

alias fmt := fmt-rs
alias fmt-check := fmt-rs-check

# Format Rust code (cargo fmt)
[group: 'format']
fmt-rs:
    cargo +nightly fmt --all

# Check Rust code format (cargo fmt --check)
[group: 'format']
fmt-rs-check:
    cargo +nightly fmt --all -- --check

# Format specific Rust file (cargo fmt <file>)
[group: 'format']
fmt-rs-file FILE:
    cargo +nightly fmt -- {{FILE}}

# Format shell scripts (shfmt)
[group: 'format']
fmt-sh:
    #!/usr/bin/env bash
    set -e # Exit on error

    # Check if shfmt is installed
    if ! command -v "shfmt" &> /dev/null; then
        >&2 echo "=============================================================="
        >&2 echo "Required command 'shfmt' not available"
        >&2 echo ""
        >&2 echo "Please install shfmt using your preferred package manager:"
        >&2 echo "  brew install shfmt"
        >&2 echo "  apt-get install shfmt"
        >&2 echo "  pacman -S shfmt"
        >&2 echo "  go install mvdan.cc/sh/v3/cmd/shfmt@latest"
        >&2 echo ""
        >&2 echo "See: https://github.com/mvdan/sh"
        >&2 echo "=============================================================="
        exit 1
    fi

    shfmt --write install

# Check shell scripts format (shfmt --diff)
[group: 'format']
fmt-sh-check:
    #!/usr/bin/env bash
    set -e # Exit on error

    # Check if shfmt is installed
    if ! command -v "shfmt" &> /dev/null; then
        >&2 echo "=============================================================="
        >&2 echo "Required command 'shfmt' not available"
        >&2 echo ""
        >&2 echo "Please install shfmt using your preferred package manager:"
        >&2 echo "  brew install shfmt"
        >&2 echo "  apt-get install shfmt"
        >&2 echo "  pacman -S shfmt"
        >&2 echo "  go install mvdan.cc/sh/v3/cmd/shfmt@latest"
        >&2 echo ""
        >&2 echo "See: https://github.com/mvdan/sh"
        >&2 echo "=============================================================="
        exit 1
    fi

    shfmt --diff install


## Check

alias check := check-rs

# Check Rust code (cargo check --all-targets)
[group: 'check']
check-rs *EXTRA_FLAGS:
    cargo check --all-targets {{EXTRA_FLAGS}}

# Lint Rust code (cargo clippy --all-targets)
[group: 'check']
clippy *EXTRA_FLAGS:
    cargo clippy --all-targets {{EXTRA_FLAGS}}

# Lint shell scripts (shellcheck)
[group: 'check']
check-sh:
    #!/usr/bin/env bash
    set -e # Exit on error

    # Check if shellcheck is installed
    if ! command -v "shellcheck" &> /dev/null; then
        >&2 echo "=============================================================="
        >&2 echo "Required command 'shellcheck' not available"
        >&2 echo ""
        >&2 echo "Please install shellcheck using your preferred package manager:"
        >&2 echo "  brew install shellcheck"
        >&2 echo "  apt-get install shellcheck"
        >&2 echo "  dnf install ShellCheck"
        >&2 echo "  pacman -S shellcheck"
        >&2 echo ""
        >&2 echo "See: https://github.com/koalaman/shellcheck"
        >&2 echo "=============================================================="
        exit 1
    fi

    shellcheck -x -o all -S style install


## Build

alias build := build-ampup

# Build ampup binary (cargo build --release)
[group: 'build']
build-ampup *EXTRA_FLAGS:
    cargo build --release -p ampup {{EXTRA_FLAGS}}


## Testing

# Run tests
[group: 'test']
test *EXTRA_FLAGS:
    #!/usr/bin/env bash
    set -e # Exit on error

    if command -v "cargo-nextest" &> /dev/null; then
        cargo nextest run {{EXTRA_FLAGS}}
    else
        >&2 echo "================================================================="
        >&2 echo "WARNING: cargo-nextest not found - using 'cargo test' fallback"
        >&2 echo ""
        >&2 echo "For faster test execution, consider installing cargo-nextest:"
        >&2 echo "  cargo install --locked cargo-nextest@^0.9"
        >&2 echo "================================================================="
        sleep 1 # Give the user a moment to read the warning
        cargo test {{EXTRA_FLAGS}}
    fi


## Web

# Install web dependencies (pnpm install)
[group: 'web']
[working-directory: 'web']
web-pnpm-install:
    pnpm install

# Build web site (pnpm build)
[group: 'web']
[working-directory: 'web']
web-build:
    pnpm build

# Run web development server (pnpm dev)
[group: 'web']
[working-directory: 'web']
web-dev:
    pnpm dev

# Preview production web build (pnpm preview)
[group: 'web']
[working-directory: 'web']
web-preview:
    pnpm preview


## Misc

PRECOMMIT_CONFIG := ".github/pre-commit-config.yaml"
PRECOMMIT_DEFAULT_HOOKS := "pre-commit pre-push"

# Install Git hooks
[group: 'misc']
install-git-hooks HOOKS=PRECOMMIT_DEFAULT_HOOKS:
    #!/usr/bin/env bash
    set -e # Exit on error

    # Check if prek is installed
    if ! command -v "prek" &> /dev/null; then
        >&2 echo "=============================================================="
        >&2 echo "Required command 'prek' not available"
        >&2 echo ""
        >&2 echo "Please install prek using your preferred package manager:"
        >&2 echo "  brew install prek"
        >&2 echo "  cargo install --locked prek"
        >&2 echo "  uv tool install prek"
        >&2 echo "  pip install prek"
        >&2 echo "  npm install -g @j178/prek"
        >&2 echo ""
        >&2 echo "See: https://github.com/j178/prek"
        >&2 echo "=============================================================="
        exit 1
    fi

    # Install all Git hooks (see PRECOMMIT_HOOKS for default hooks)
    prek install --config {{PRECOMMIT_CONFIG}} {{replace_regex(HOOKS, "\\s*([a-z-]+)\\s*", "--hook-type $1 ")}}

# Remove Git hooks
[group: 'misc']
remove-git-hooks HOOKS=PRECOMMIT_DEFAULT_HOOKS:
    #!/usr/bin/env bash
    set -e # Exit on error

    # Check if prek is installed
    if ! command -v "prek" &> /dev/null; then
        >&2 echo "=============================================================="
        >&2 echo "Required command 'prek' not available"
        >&2 echo ""
        >&2 echo "Please install prek using your preferred package manager:"
        >&2 echo "  brew install prek"
        >&2 echo "  cargo install --locked prek"
        >&2 echo "  uv tool install prek"
        >&2 echo "  pip install prek"
        >&2 echo "  npm install -g @j178/prek"
        >&2 echo ""
        >&2 echo "See: https://github.com/j178/prek"
        >&2 echo "=============================================================="
        exit 1
    fi

    # Remove all Git hooks (see PRECOMMIT_HOOKS for default hooks)
    prek uninstall --config {{PRECOMMIT_CONFIG}} {{replace_regex(HOOKS, "\\s*([a-z-]+)\\s*", "--hook-type $1 ")}}
