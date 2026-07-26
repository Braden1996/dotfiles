<p align="center">
  <img src="assets/banner.webp" alt="Braden's Dotfiles" width="100%" />
</p>

<p align="center">
  <a href="https://github.com/Braden1996/dotfiles/actions/workflows/ci.yml"><img src="https://github.com/Braden1996/dotfiles/actions/workflows/ci.yml/badge.svg?branch=master" alt="CI" /></a>
  <a href="https://www.chezmoi.io/"><img src="https://img.shields.io/badge/managed%20with-chezmoi-2f80ed" alt="managed with chezmoi" /></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey?logo=apple" alt="macOS" />
  <img src="https://img.shields.io/badge/shell-zsh%20%2B%20fish-4eaa25" alt="zsh and fish" />
</p>

macOS-first development environment managed with [chezmoi](https://www.chezmoi.io/).
GitHub keys and git identities come from 1Password and are never written to disk.

---

## Set up a new machine

1. **Install.**

   ```bash
   xcode-select --install
   sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/Braden1996/dotfiles.git
   ```

   HTTPS, not SSH — the key this sets up doesn't exist yet.

2. **Answer the prompts.** See [Init data](#init-data). No key material is asked for.

3. **Install the helper commands.** No-op if step 1 applied; needed if you re-inited without applying.

   ```bash
   chezmoi apply ~/.local/bin
   ```

4. **Give `op` access.**
   - *Personal:* 1Password → Settings → Developer → **Integrate with 1Password CLI**. The SSH agent setting is not used.
   - *Work:* `dotfiles-keys store-token` (prompts without echoing; never hits argv, `ps` or history).

5. **Set up this machine's keys.** A personal machine creates and publishes its
   own keys. A work machine syncs keys that were first provisioned from a
   trusted personal machine; see [Provision a work machine](#provision-a-work-machine).

   ```bash
   dotfiles-keys setup
   ```

6. **Apply.** Review first — an existing machine may have unrelated pending changes.

   ```bash
   chezmoi diff && chezmoi apply
   ```

7. **Check.** `dotfiles-keys status` · `dotfiles-doctor` · `ssh -T git@github.com`

**Existing machine:** run `chezmoi init --prompt` first, then from step 3. Prompts default to
current values, so enter keeps them. Git doesn't sign until step 5 completes.

---

## Everyday commands

| Situation | Run |
| --- | --- |
| Work machine, start of day | `dotfiles-keys load` |
| Add a git identity | `dotfiles-keys identity-add <slug> <email> <owner/**> [--vault <vault>]` |
| Provision another machine's default GitHub keys | `dotfiles-keys provision <machine> --vault <vault> --github-user <login>` |
| Provision another GitHub account for an identity | `dotfiles-keys provision <machine> --identity <slug> --vault <vault> --github-user <login>` |
| Added a machine or account identity elsewhere | `dotfiles-keys sync && dotfiles-keys load` |
| Something feels wrong | `dotfiles-doctor` |
| Routine update | `dotfiles-update --check`, then `dotfiles-update` |
| Changed the source | `chezmoi diff && chezmoi apply` |
| Changed any package or plugin list | `mise run docs` |
| Before pushing repo changes | `mise run check` |
| Retire one machine | delete its default and account-specific GitHub keys + vault items, then `dotfiles-keys sync` elsewhere |
| Retire all work machines | disable the service account in 1Password |

---

## What's managed

- **Shells** — zsh + fish, pinned plugins, Starship, fzf, zoxide
- **Editors** — Cursor settings and extensions, AstroNvim v5 with a locked plugin graph
- **Terminal** — Ghostty, tmux with checksum-pinned plugins
- **Git** — SSH commit signing, one include for vault-driven identities, Graphite aliases
- **SSH** — `~/.ssh/config` per profile
- **Packages** — profile-aware Brewfile, locked mise runtimes

**Never written by an apply:** private keys, public key files, git identities, the trust store,
the service account token, `~/.gitconfig.local`. Those are either runtime-owned or machine-local.

---

## Appendix

Generated from the files that drive an apply — `mise run check:docs` fails if they drift,
`mise run docs` regenerates. Package descriptions come from Homebrew itself.

### Packages

<!-- generated:packages -->
<!-- Do not edit by hand: run `mise run docs`. -->
#### Taps

- `withgraphite/tap`

#### Formulae

*Shell and prompt*

- `antidote` — Plugin manager for zsh, inspired by antigen and antibody
- `fish` — User-friendly command-line shell for UNIX-like operating systems
- `starship` — Cross-shell prompt for astronauts
- `zsh` — UNIX shell (command interpreter)

*Core CLI tools*

- `bat` — Clone of cat(1) with syntax highlighting and Git integration
- `chezmoi` — Manage your dotfiles across multiple diverse machines, securely
- `eza` — Modern, maintained replacement for ls
- `fd` — Simple, fast and user-friendly alternative to find
- `fzf` — Command-line fuzzy finder written in Go
- `hyperfine` — Command-line benchmarking tool
- `jq` — Lightweight and flexible command-line JSON processor
- `ripgrep` — Search tool like grep and The Silver Searcher
- `yazi` — Blazing fast terminal file manager written in Rust, based on async I/O
- `zoxide` — Shell extension to navigate your filesystem faster

*Development and validation*

- `gh` — GitHub command-line tool
- `git` — Distributed revision control system
- `git-delta` — Syntax-highlighting pager for git and diff output
- `gnupg` — GNU Privacy Guard (OpenPGP)
- `mise` — Polyglot runtime manager (asdf rust clone)
- `shellcheck` — Static analysis and lint tool, for (ba)sh scripts
- `shfmt` — Autoformat shell script source code
- `taplo` — TOML toolkit written in Rust
- `tmux` — Terminal multiplexer
- `withgraphite/tap/graphite` — Allows you to manage your stacked changes and submit them for review on GitHub

#### Casks

*Credentials*

- `1password-cli` — Command-line interface for 1Password

*Desktop tools*

- `cursor` — Write, edit, and chat about your code with AI
- `font-fira-code-nerd-font`
- `ghostty` — Terminal emulator that uses platform-native UI and GPU acceleration
- `1password` — Password manager that keeps all passwords secure behind one password _(personal only)_

<!-- /generated:packages -->

### Runtimes and toolchains

<!-- generated:runtimes -->
<!-- Do not edit by hand: run `mise run docs`. -->
#### Global runtimes (mise)

- `biome` 2
- `node` 22
- `python` 3.13
- `rust` stable
- `terraform` 1.15

#### Repository validation toolchain

- `actionlint` 1.7.12
- `biome` 2.5.3
- `chezmoi` 2.71.0
- `gitleaks` 8.30.1
- `jq` 1.8.1
- `shellcheck` 0.11.0
- `shfmt` 3.13.1
- `starship` 1.26.0
- `stylua` 2.5.2
- `taplo` 0.10.0
- `zizmor` 1.26.1
- `aqua:Kampfkarren/selene` 0.31.0

<!-- /generated:runtimes -->

### Editor and shell plugins

<!-- generated:editor-and-shell -->
<!-- Do not edit by hand: run `mise run docs`. -->
#### Cursor extensions (19)

- `aaron-bond.better-comments`
- `alefragnani.project-manager`
- `anysphere.remote-ssh`
- `biomejs.biome`
- `catppuccin.catppuccin-vsc`
- `dbaeumer.vscode-eslint`
- `eamodio.gitlens`
- `esbenp.prettier-vscode`
- `graphite.gti-vscode`
- `hashicorp.terraform`
- `naumovs.color-highlight`
- `oxc.oxc-vscode`
- `pflannery.vscode-versionlens`
- `prisma.prisma`
- `redhat.vscode-yaml`
- `shardulm94.trailing-spaces`
- `streetsidesoftware.code-spell-checker`
- `thang-nm.flow-icons`
- `typescriptteam.native-preview`

#### Zsh plugins (Antidote, all pinned)

- `mattmc3/zephyr/plugins/helper` @ 35b5e56
- `mattmc3/zephyr/plugins/prompt` @ 35b5e56
- `zsh-users/zsh-completions/src` @ 8b97eaf
- `mattmc3/zephyr/plugins/completion` @ 35b5e56
- `mattmc3/zephyr/plugins/compstyle` @ 35b5e56
- `ohmyzsh/ohmyzsh/plugins/git` @ 7c10d98
- `Aloxaf/fzf-tab` @ 0983009
- `jirutka/zsh-shift-select` @ da46099
- `zsh-users/zsh-autosuggestions` @ 85919cd
- `zdharma-continuum/fast-syntax-highlighting` @ 3d574cc

#### Neovim

- AstroNvim v5 with 46 plugins pinned in `dot_config/nvim/lazy-lock.json`.
- The lock is not listed here: it churns on every plugin update. Read the file.

<!-- /generated:editor-and-shell -->

### Pinned externals

<!-- generated:externals -->
<!-- Do not edit by hand: run `mise run docs`. -->
Fetched at apply time and verified against a recorded SHA-256.

- `.tmux/plugins/tpm` — https://codeload.github.com/tmux-plugins/tpm/tar.gz/e261deb1b47614eed3400089ce7197dc68acc4eb
- `.tmux/plugins/tmux-sensible` — https://codeload.github.com/tmux-plugins/tmux-sensible/tar.gz/25cb91f42d020f675bb0a2ce3fbd3a5d96119efa
- `.tmux/plugins/tmux` — https://codeload.github.com/dracula/tmux/tar.gz/a4612670d77c8546690dc79d23eae591c6dfa8d3

<!-- /generated:externals -->

### Commands and hooks

<!-- generated:apply-surface -->
<!-- Do not edit by hand: run `mise run docs`. -->
#### Scripts that run during an apply

These execute on your machine. Read them before applying on a host you do not control.

- `99-setup-reminders.sh` (once)
- `00-install-homebrew.sh` (once)
- `05-install-packages.sh` (on change)
- `10-install-mise-tools.sh` (on change)
- `20-install-cursor-extensions.sh` (on change)
- `20-macos-personal-settings.sh` (on change)

#### Commands installed to `~/.local/bin`

##### `dotfiles-doctor`

```text
Usage: dotfiles-doctor [--project PATH]

Run workstation checks without changing managed state. With --project, also
inspect an Nx workspace's telemetry choice and .cursorignore coverage.
```

##### `dotfiles-keys`

```text
Usage: dotfiles-keys <command>

Commands:
  setup         Guided first run for this machine's credential backend
  provision     Create+publish keys for another machine/account
                provision <machine> [--identity <slug>] [--vault <vault>]
                                      [--github-user <login>]
  store-token   Store the service account token in the macOS keychain (work only)
  status        Report the credential backend, agent, and which keys are usable
  generate      Create this machine's SSH keys inside 1Password
  publish       Add this machine's public keys to your GitHub account
  sync          Write public keys, git identities and the trust store from the vault
  sync-signers  Rebuild only ~/.ssh/allowed_signers from every machine in the vault
  identity-add  Add a git identity
                identity-add <slug> <email> <owner/** | owner/repo>
                             [--vault <vault>]
  load          Read this machine's keys from 1Password into the ssh-agent
  unload        Drop the loaded keys from the ssh-agent
  token         Print the GitHub token from the vault, for GH_TOKEN

Keys are per-machine, named for this host, so retiring one machine does not
rotate any other machine's credentials. Private keys are never written to
disk: `generate` creates them inside 1Password and `load` streams them straight
into the agent.
```

##### `dotfiles-update`

```text
Usage: dotfiles-update [--check] [--refresh-antidote-pins]

Without flags, fast-forward the Chezmoi source, apply it, upgrade only the
packages declared by the managed Brewfile, upgrade mise tools within their
configured series, and update declared Cursor extensions.

  --check  Report available updates and run dotfiles-doctor without changing
           managed files or installed versions.
  --refresh-antidote-pins
           Explicitly refresh every pinned Antidote plugin to its upstream
           HEAD. This changes the Chezmoi source and is never done by default.
  -h       Show this help.
```

Plus package-manager shims that take the underlying tool's own arguments: `pnpm` `pnpx` `yarn` 

#### Repository checks

- `mise run check:actions` — Lint GitHub Actions workflows
- `mise run check:data` — Validate repository TOML and JSON data
- `mise run check:chezmoi` — Render and apply both machine profiles in disposable homes
- `mise run check:keys` — Exercise dotfiles-keys against isolated 1Password, GitHub, and agent fakes
- `mise run docs` — Regenerate the README inventory from its sources of truth
- `mise run check:docs` — Fail if the README inventory no longer matches what is installed
- `mise run check:lua` — Check Neovim formatting and Lua diagnostics
- `mise run check:scripts` — Lint repository validation scripts
- `mise run check:secrets` — Scan Git history and the working tree for secrets
- `mise run check:static` — Run fast, platform-independent checks
- `mise run check` — Run the complete local validation suite
- `mise run format:lua` — Format active Neovim Lua files

<!-- /generated:apply-surface -->

### Init data

<!-- generated:init-data -->
<!-- Do not edit by hand: run `mise run docs`. -->
Prompted once and stored only in the machine-local chezmoi config.

| Key | Prompt |
| --- | --- |
| `machineType` | Machine type (personal/work) |
| `gitName` | Git author name |
| `defaultEmail` | Default email address (used when no identity scope matches) |
| `machineName` | Short name for this machine, used to scope its GitHub keys |
| `opVault` | 1Password vault for this machine's GitHub keys (name or ID) |
| `opTokenKeychainService` | Keychain service name holding the 1Password service account token |
| `credentialBackend` | Derived from `machineType`, not prompted |

<!-- /generated:init-data -->

### Privacy environment

<!-- generated:privacy-env -->
<!-- Do not edit by hand: run `mise run docs`. -->
Exported by Fish, Zsh and Bash alike.

- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`
- `DO_NOT_TRACK=1`
- `GH_TELEMETRY=0`
- `GRAPHITE_DISABLE_TELEMETRY=1`
- `GROK_TELEMETRY_ENABLED=0`
- `HOMEBREW_NO_ANALYTICS=1`
- `SST_TELEMETRY_DISABLED=1`
- `YARN_ENABLE_TELEMETRY=0`

<!-- /generated:privacy-env -->

---

## Concepts

### Credentials

Both profiles work the same way: `dotfiles-keys load` reads every key pair
configured for this machine from 1Password and adds it to the **OS ssh-agent**.
That includes account-specific keys attached to git identities. Nothing is
written to disk, and nothing gates its use.

| Profile | Key lifetime in the agent | If the service account is revoked |
| --- | --- | --- |
| `personal` | Until logout | Nothing — it authenticates as you, not via the service account |
| `work` | 9 hours | Next load fails; access ends |

- **The 1Password SSH agent is deliberately not used.** It asks approval per client, which no
  unattended process can answer — so it would stop agent harnesses and CI from pushing or
  signing. 1Password is the source of truth for the key, not a gate on using it. The `op` CLI
  itself works fine non-interactively, which is what makes this possible.
- **Nothing durable on a work machine.** Writing a key file would leave a working credential
  behind, so a work machine is never told to use an on-disk key even if one exists.
- **Keys are per-machine**, titled for the host, so retiring one machine only
  removes that machine's default and account-specific keys; no other machine
  rotates, and signatures stay attributable.
- **The work TTL** applies to the default pair and every account-specific pair,
  bounding how long a revoked machine keeps working. Personal machines don't
  expire: revocation isn't their threat model, and a lapsed key would strand
  overnight jobs.
- **Copies already extracted survive revocation.** Per-machine keys bound the blast radius to
  one machine; they don't eliminate it.
- **The local trust store is vault-scoped.** `sync-signers` trusts only signing
  keys and identity mappings from this machine's configured vault. GitHub can
  still verify signatures made by keys in other vaults.
- After a reboot, run `dotfiles-keys load` once. `dotfiles-doctor` says when it's missing.

### Git identities

An identity is an email plus a rule for which repos it applies to. There is no fixed slot for
"work" or "side project" — those were the same thing modelled twice.

- **One 1Password item per identity**, in the vault this machine is configured
  for. That vault *is* the scope: the machine sees only identities deliberately
  placed in a vault it can read.
- **Scopes** are `owner/**` for a whole org or `owner/repo` for one repo. Exact repos emit both
  the bare and `.git` URL forms — a suffixless clone does not match a suffixed pattern, which
  silently drops the identity.
- **Overlapping scopes: last match wins**, so identities are sorted by slug to stay deterministic.
- **An identity may own a separate GitHub account.** If
  `GitHub Machine Auth (<machine> <slug>)` exists in the vault, that identity
  gets its own auth and signing keys, an ssh alias `github-<slug>`, and signs
  with its own key — a key on one account cannot verify a commit authored under
  another account's email. `sync` writes the public configuration and `load`
  automatically loads the account-specific private keys into the agent.
- **Clone through the account alias.** A `personal` identity uses
  `github-personal`, so clone it as
  `git@github-personal:owner/repo.git`. For an existing clone:
  ```bash
  git remote set-url origin git@github-personal:owner/repo.git
  ```
  The generated identity rules match both ordinary GitHub URLs and alias URLs,
  but authentication uses the account selected by the hostname.
- **`provision` creates keys from a trusted personal machine already logged
  into the GitHub account that should own them.** The target work laptop never
  has to log into either GitHub account.
- `~/.gitconfig` carries one static include; `dotfiles-keys sync` writes the routing and the
  per-identity files. chezmoi never templates them — it only knows the machine it rendered on,
  and only the vault knows how many identities exist.
- `dotfiles-update` refreshes them, and doesn't fail the update if the vault is unreachable.

#### Provision a work machine

Run this on a trusted personal machine with writable 1Password access and both
GitHub accounts already known to `gh`. First select the work GitHub account and
provision the target machine's default pair:

```bash
gh auth switch -h github.com -u <work-github-login>
dotfiles-keys provision <work-machine> \
  --vault '<work-vault>' \
  --github-user <work-github-login>
```

Then select the personal account, store its repository identity in the same
vault, and provision a distinct pair for that account:

```bash
gh auth switch -h github.com -u Braden1996
dotfiles-keys identity-add personal <personal-email> 'Braden1996/**' \
  --vault '<work-vault>'
dotfiles-keys provision <work-machine> \
  --identity personal \
  --vault '<work-vault>' \
  --github-user Braden1996
```

If either account lacks permission to publish signing keys, refresh that
account before provisioning:

```bash
gh auth refresh -h github.com -s admin:ssh_signing_key
```

On the target work machine, derive its local public files and identity routing,
review the managed changes, load every configured key pair, and verify:

```bash
dotfiles-keys sync
chezmoi diff
chezmoi apply
dotfiles-keys load
dotfiles-keys status

ssh -T git@github.com
ssh -T git@github-personal
```

`--github-user` is a safety check: provisioning stops if `gh` is currently
using a different account, rather than publishing a key to the wrong owner.

The work service account remains read-only, so it cannot create, change or
publish keys. Read-only does **not** mean it cannot retrieve them: putting the
Braden1996 pair in `<work-vault>` deliberately gives that service account and
work machine access to the personal GitHub account. The helper keeps private
keys off disk and expires its agent copies, but any independently extracted
copy survives token revocation. Use a distinct pair per work machine, grant the
service account access only to the required vault, and delete both the GitHub
keys and vault items when retiring that machine.

### SSH signing, not GPG

- `gpg --import` persists the private key into `~/.gnupg`, defeating the revocation property
  above. An agent-held SSH key signs with nothing on disk.
- GitHub marks SSH signatures **Verified** exactly like GPG.
- Existing GPG keys still verify old commits; nothing wires them into git. For one repo:
  `git config --local gpg.format openpgp`.

### The app and the CLI are separate

- The desktop app ships `op-ssh-sign`, **not** `op`. Install the CLI separately.
- **"Integrate with 1Password CLI"** doesn't install anything — it lets the app *authenticate* an
  `op` you installed. Setting on and `op` missing is a normal state.
- Personal machines need `op` for setup, sync and `load`. Once loaded, auth and signing are
  pure ssh-agent operations and touch 1Password not at all.
- Git signs via plain `ssh-keygen`, not `op-ssh-sign`, so one gitconfig works on a machine with
  no app — and `ssh-keygen -Y sign` reads `SSH_AUTH_SOCK`, which is why pinning `IdentityAgent`
  would not have covered signing anyway.

### The GitHub token (optional)

`gh` needs an API token and a work machine can't log in interactively:

```bash
GH_TOKEN="$(dotfiles-keys token)" gh pr list
```

Nothing creates it — GitHub has no API for minting fine-grained PATs. Make one in the UI, store
it in the vault as `GitHub Machine PAT` with the token in its `credential` field. Revoking the
service account does **not** revoke a copy already fetched, so keep the expiry short.

### Privacy

- Telemetry opt-outs are listed under [Privacy environment](#privacy-environment); the
  provisioning hook also persists the ones that are CLI settings rather than env vars.
- Terraform keeps security bulletins, drops the anonymous checkpoint signature.
- Update and security checks are **not** treated as telemetry — disabling them would hide
  security notices.
- Shell history stays local: prefix a command with a space, or use `fish --private`.
- Gitleaks scans history and the working tree on every run.

### Validation

```bash
mise trust && mise install --locked
mise run check
```

- Renders **both** profiles, dry-runs, applies twice to disposable homes, asserts the second
  apply is clean.
- Lints rendered scripts by shebang, so the doctor and credential helper are covered.
- Asserts no apply writes key material, that a work machine never references a durable on-disk
  key, that chezmoi manages neither the key files nor identities, and that `brew`/`cask` entries
  really are formulae and casks.
- CI repeats it on Ubuntu and macOS across two chezmoi versions.

### Layout

```text
.chezmoi.toml.tmpl     # prompts → machine-local config
.chezmoidata.toml      # shared non-secret data
.chezmoiexternal.toml  # checksum-pinned externals
.chezmoiignore         # repo-only and platform exclusions
.chezmoiremove         # files retired from source
dot_config/            # fish, zsh, nvim, ghostty, cursor, mise, homebrew
private_dot_ssh/       # ssh config (public material only)
dot_local/bin/         # dotfiles-keys, dotfiles-doctor, dotfiles-update
run_*                  # guarded bootstrap and apply hooks
scripts/               # generate-docs, validate-chezmoi
```
