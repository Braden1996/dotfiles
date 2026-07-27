# Dotfiles

My macOS workstation setup, managed with
[chezmoi](https://www.chezmoi.io/). `braden-dots` is the stable control plane
after the first apply; the raw Chezmoi command remains the bootstrap path.

Private GitHub keys and application secrets live in 1Password. This repository
contains configuration and non-secret coordinates, never secret values.

## Software

<!-- generated:software -->
<!-- Do not edit by hand: run `mise run docs`. -->
| Scope | Installed |
| --- | --- |
| Homebrew formulae · both | `antidote`, `bat`, `chezmoi`, `eza`, `fd`, `fish`, `fzf`, `gh`, `git`, `git-delta`, `gnupg`, `hyperfine`, `jq`, `mise`, `ripgrep`, `shellcheck`, `shfmt`, `starship`, `taplo`, `tmux`, `withgraphite/tap/graphite`, `yazi`, `zoxide`, `zsh` |
| Homebrew casks · both | `1password-cli`, `cursor`, `font-atkinson-hyperlegible`, `font-fira-code-nerd-font`, `ghostty` |
| Homebrew · personal only | `1password` |
| Homebrew · work only | — |
| mise runtimes · both | `biome 2`, `node 22`, `python 3.13`, `rust stable`, `terraform 1.15` |

Extensions/plugins: [Cursor](dot_config/cursor/extensions.txt) 19 · [Zsh](dot_zsh_plugins.txt) 10 · [Neovim](dot_config/nvim/lazy-lock.json) 46 · tmux 3
<!-- /generated:software -->

Configured if already installed: Neovim/AstroNvim, Zed, OrbStack, Antigravity,
Bun, Android SDK and Safe Chain. Flow Icons is configured for both profiles;
Kimi/Grok runtimes are personal-only. Kimi, Grok, Zed and Neovim are not
installed here.

- `personal` adds the 1Password app, personal macOS settings and personal tools.
- `work` keeps the shared development stack and excludes Kimi/Grok runtime
  configuration while retaining the shared agent guidance. Existing
  third-party installs are not removed.

## New personal Mac

1. Install Apple’s command-line tools: `xcode-select --install`.
2. Bootstrap over HTTPS and choose `personal`:

   ```sh
   sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply \
     https://github.com/Braden1996/dotfiles.git
   ```

3. Enable **1Password → Settings → Developer → Integrate with 1Password CLI**,
   then run `op signin` and `gh auth login`.
4. Finish onboarding: `braden-dots init`.

## New work Mac

1. On a trusted personal Mac, provision the intended account into the
   work-readable vault. Ensure the same vault contains a `Flow Icons License`
   item with a concealed `license key` field:

   ```sh
   gh auth switch -h github.com -u <github-login>
   braden-dots identity provision <machine> \
     --vault '<work-vault-id>' \
     --github-user <github-login>
   ```

2. Install Apple’s command-line tools, run the bootstrap command above and
   choose `work`. Enter the same `<machine>` name used in step 1.
3. Store the read-only 1Password service-account token:
   `braden-dots identity store-token`.
4. Finish onboarding: `braden-dots init`.

For an additional GitHub account on a work Mac, see
[GitHub credentials](docs/credentials.md).

## Everyday workflow

```sh
braden-dots status
braden-dots sync
braden-dots update --check
```

Dirty Chezmoi source is normal: `sync` fetches for awareness, applies the local
source as-is, and never stages, stashes, commits, or rewrites it.

To save dotfiles work:

```sh
braden-dots source diff
braden-dots source publish -m "Describe the dotfiles change"
```

If a rebase stops, resolve the listed files semantically and then continue, or
abort to restore the pre-rebase commit:

```sh
braden-dots source conflicts
braden-dots source continue
# or
braden-dots source abort
```

After a successful continuation, rerun `braden-dots source publish`.

## Commands

| Task | Command |
| --- | --- |
| Finish onboarding | `braden-dots init` |
| Apply local source | `braden-dots apply` |
| Fetch safely and apply | `braden-dots sync` |
| Commit, reconcile, check, push | `braden-dots source publish -m "…"` |
| Check / apply updates | `braden-dots update --check` · `braden-dots update` |
| Summarize machine state | `braden-dots status` |
| Diagnose workstation/project | `braden-dots doctor [--project PATH]` |

## Credential model

- Chezmoi owns configuration and the source used to generate managed targets.
- 1Password owns secrets and private keys; Chezmoi never fetches them while
  rendering.
- Public keys, trust data, and Git/SSH identity files are generated local
  projections. Private SSH keys are streamed only into the OS agent.
- Personal Macs authenticate `op` through the desktop app.
- Work Macs use a vault-scoped service account; loaded keys expire after nine
  hours.
- Keys are unique per machine and account, so one machine can be retired
  without rotating every other machine.
- Put only work-approved secrets, such as Flow Icons, in a work-readable vault.

Details: [GitHub credentials](docs/credentials.md) ·
[application secrets](docs/secrets.md).
