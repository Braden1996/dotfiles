<p align="center">
  <img src="assets/banner.webp" alt="Braden's Dotfiles" width="100%" />
</p>

<p align="center">
  <a href="https://github.com/Braden1996/dotfiles/actions/workflows/ci.yml"><img src="https://github.com/Braden1996/dotfiles/actions/workflows/ci.yml/badge.svg?branch=master" alt="CI" /></a>
  <a href="https://www.chezmoi.io/"><img src="https://img.shields.io/badge/managed%20with-chezmoi-2f80ed" alt="managed with chezmoi" /></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey?logo=apple" alt="macOS" />
  <img src="https://img.shields.io/badge/shell-zsh%20%2B%20fish-4eaa25" alt="zsh and fish" />
</p>

A macOS-first development environment managed with
[chezmoi](https://www.chezmoi.io/). It supports personal and work profiles,
keeps machine-bound credentials out of Git, and makes installation, updates,
health checks, and repository validation explicit.

## Quick start

On a new Mac:

```bash
xcode-select --install
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply Braden1996
```

The first apply can install Homebrew, the declared Brewfile, mise runtimes,
Cursor extensions, and pinned tmux plugins. Review the source before running it
on a machine you do not control.

### Init data

Chezmoi stores these values only in the machine's local config:

| Key | Purpose |
| --- | --- |
| `machineType` | Selects the `personal` or `work` profile. |
| `gitName`, `personalEmail` | Default Git identity. |
| `sideProjectEmail`, `sideProjectGitHubRepo` | Optional identity for one selected side-project repository. |
| `workEmail`, `workGitHubOrg` | Optional work identity and remote-based routing. |
| `gpgKeyPersonalEmail`, `gpgKeyWorkEmail` | Existing GPG signing key IDs; blank is allowed during bootstrap. |

To change a prompted value later, use `--prompt` explicitly:

```bash
chezmoi init --prompt
chezmoi diff
chezmoi apply
```

Plain `chezmoi init` reuses the existing `prompt*Once` values.

Cursor's Flow Icons license remains local and unmanaged. The Cursor settings
modify-template carries an existing value forward without committing it, so no
secret-manager setup is required. The first local `chezmoi diff` can show that
line if its position changes; do not paste that diff into public logs.

## What is managed

- Zsh and Fish configurations with pinned Antidote plugins, Starship, fzf,
  zoxide, modern CLI defaults, and shared privacy environment variables.
- Cursor settings, keybindings, and an idempotent extension manifest.
- AstroNvim v5 with a locked plugin graph, trusted project-local config, and a
  debounced Neo-tree preview that uses an isolated scratch buffer.
- Ghostty, tmux, Git/GPG signing, Graphite aliases, Terraform checkpoint policy,
  and global ignore rules.
- A Brewfile for missing macOS dependencies and a locked mise configuration for
  Node, Python, Rust, Terraform, and Biome.
- Checksum-pinned tmux externals. Normal applies do not silently upgrade Brew
  packages, mise series, Cursor extensions, or Antidote pins.

SSH host configuration, private keys, login sessions, editor workspace state,
and other machine-specific credentials remain unmanaged.

## Operations

Preview and apply source changes:

```bash
chezmoi diff
chezmoi apply
chezmoi verify
```

Inspect workstation health without changing managed state:

```bash
dotfiles-doctor
dotfiles-doctor --project /path/to/nx-workspace
```

Check for updates, or perform the reviewed update flow:

```bash
dotfiles-update --check
dotfiles-update
```

`dotfiles-update` requires a clean source worktree, fast-forwards with
`--ff-only`, applies the source, upgrades only declared dependencies within
their configured series, re-adds the generated mise lock, updates Cursor
extensions, and finishes with the doctor. Antidote pins move only when requested:

```bash
dotfiles-update --refresh-antidote-pins
```

## Manual setup

The post-setup reminder reports anything still missing. The usual one-time work
is:

1. Generate/import the required GPG keys, add their public keys to GitHub, then
   record their IDs with `chezmoi init --prompt`.
2. Generate an SSH key if needed and keep `~/.ssh/config` local to the machine.
3. In Cursor, verify account-level Privacy Mode and usage-data choices. These
   controls are not represented reliably by editor settings.

If you later choose to use 1Password CLI integration, its account-level
usage-data preference remains a manual consent setting.

## Privacy and security defaults

- Homebrew analytics and mise version-install tracking are disabled.
- Cursor core, feedback, GitLens, and Red Hat telemetry are disabled; workspace
  trust and protocol prompts are enabled, while app and extension security
  updates remain on.
- Terraform keeps update/security bulletin checks but disables the anonymous
  checkpoint signature.
- `DO_NOT_TRACK`, `GH_TELEMETRY`, Grok, Graphite, Yarn, and Homebrew opt-outs are
  shared by Fish, Zsh, and Bash.
- Grok also has telemetry, trace uploads, Mixpanel, and codebase uploads disabled
  in `~/.grok/config.toml`.
- Gitleaks scans Git history and the working tree, including a dedicated rule
  that catches a hardcoded Flow Icons license.
- GitHub Actions, Neovim plugins, validation tools, mise artifacts, and tmux
  externals are pinned; generated locks are checked for unexpected mutation.

Update and security checks are intentionally not treated as telemetry. Disabling
all network checks would hide extension, application, package, and Terraform
security notices.

### Sensitive sessions

Shell history stays local. Prefix a command with a space to exclude it from
Fish, Zsh, or Bash history, or start `fish --private` for a session that keeps
no history. A Neovim session that avoids ShaDa, swap, undo, and backup state can
be started with:

```bash
nvim -i NONE -n --cmd 'set noswapfile noundofile nobackup nowritebackup'
```

These modes do not conceal command arguments from the process list or external
tools. Avoid placing credentials directly on command lines. The doctor also
reminds you to review Docker Desktop and macOS analytics after installations or
major upgrades; their mutable settings stores are deliberately unmanaged.

## Repository validation

The repository has a separate, checksum-locked mise toolchain for macOS arm64
and Linux x64:

```bash
mise trust
mise install --locked
mise run check
```

The suite runs Actionlint and Zizmor, Taplo, Biome, Gitleaks, ShellCheck and
Shfmt, StyLua and Selene, shell syntax checks, Starship/tmux/Ghostty validators
when available, and a network-free isolated Neovim bootstrap. It fully renders
both personal and work profiles, performs a complete dry-run, then applies twice
to disposable homes and verifies the second apply is clean.

CI repeats the profile test on Ubuntu and macOS with both the declared minimum
and current chezmoi versions. Actions have read-only default permissions,
concurrency cancellation, immutable pins, and weekly Dependabot updates.

## Layout

```text
.
├── .chezmoi.toml.tmpl          # machine-local prompt data
├── .chezmoidata.toml           # shared non-secret data
├── .chezmoiexternal.toml       # checksum-pinned externals
├── .chezmoiignore              # repo-only and platform exclusions
├── .mise.toml / mise.lock      # repository validation toolchain
├── dot_config/
│   ├── cursor/                  # extension manifest
│   ├── fish/ and zsh/           # modular shell configuration
│   ├── ghostty/ and nvim/       # canonical terminal/editor configs
│   ├── homebrew/Brewfile        # declarative macOS packages
│   └── mise/                    # global runtime config and lock
├── private_Library/.../Cursor/  # macOS Cursor user settings
├── dot_local/bin/               # doctor and controlled updater
├── run_*                         # guarded bootstrap/apply hooks
└── scripts/validate-chezmoi      # disposable-home test harness
```
