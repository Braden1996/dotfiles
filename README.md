# Dotfiles

My macOS workstation setup, managed with
[chezmoi](https://www.chezmoi.io/). This is the rebuild and day-to-day cheat
sheet.

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
Kimi/Grok integration is personal-only. Kimi, Grok, Zed and Neovim are not
installed here.

- `personal` adds the 1Password app, personal macOS settings and personal tools.
- `work` keeps the shared development stack and excludes Kimi/Grok integration.
  Existing third-party installs are not removed.

## New personal Mac

1. Install Apple’s command-line tools: `xcode-select --install`
2. Bootstrap over HTTPS and choose `personal`:

   ```sh
   sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply \
     https://github.com/Braden1996/dotfiles.git
   ```

3. Enable **1Password → Settings → Developer → Integrate with 1Password CLI**,
   then run `op signin` and `gh auth login`.
4. Create, publish, sync and load this Mac’s keys: `dotfiles-keys setup`
5. Optional: enable premium Flow Icons:
   `dotfiles-secrets set flow-icons && dotfiles-flow-icons`
6. Review, apply and verify:

   ```sh
   chezmoi diff && chezmoi apply
   dotfiles-keys status
   dotfiles-doctor
   ssh -T git@github.com
   ```

## New work Mac

1. On a trusted personal Mac, switch `gh` to the intended account and provision
   keys and Flow Icons into the work-readable vault:

   ```sh
   gh auth switch -h github.com -u <github-login>
   dotfiles-keys provision <machine> \
     --vault '<work-vault-id>' \
     --github-user <github-login>
   dotfiles-secrets set flow-icons --vault '<work-vault-id>'
   ```

2. Install Apple’s command-line tools, run the bootstrap command above and
   choose `work`. Enter the same `<machine>` name used in step 1.
3. Store the read-only 1Password service-account token:
   `dotfiles-keys store-token`
4. Sync and load the provisioned keys: `dotfiles-keys setup`
5. Run `chezmoi diff && chezmoi apply`, then verify premium access with
   `dotfiles-secrets status flow-icons && dotfiles-flow-icons` and complete the
   personal-Mac verification commands.

For an additional GitHub account on a work Mac, see
[GitHub credentials](docs/credentials.md).

## Cheat sheet

| Task | Command |
| --- | --- |
| Review and apply | `chezmoi diff && chezmoi apply` |
| Open the source | `chezmoi cd` |
| Re-run profile prompts | `chezmoi init --prompt` |
| Set up machine keys | `dotfiles-keys setup` |
| Inspect / load credentials | `dotfiles-keys status` · `dotfiles-keys load` |
| Refresh keys and identities | `dotfiles-keys sync` |
| Add an identity | `dotfiles-keys identity-add <slug> <email> '<owner/**>' [--vault <vault>]` |
| Provision an account identity | `dotfiles-keys provision <machine> --identity <slug> --vault <vault> --github-user <login>` |
| Run `gh` as an identity | `dotfiles-keys gh <slug> -- <arguments...>` |
| Inspect application secrets | `dotfiles-secrets status` |
| Store / rotate Flow Icons | `dotfiles-secrets set flow-icons && dotfiles-flow-icons` |
| Check / apply updates | `dotfiles-update --check` · `dotfiles-update` |
| Diagnose the machine | `dotfiles-doctor` |
| Regenerate this inventory | `mise run docs` |
| Validate before pushing | `mise run check` |

## Credential model

- 1Password is the source of truth; Chezmoi never fetches secrets while
  rendering templates.
- Private SSH keys are streamed into the OS agent. Only public keys, trust data
  and generated Git routing are written locally.
- Personal Macs authenticate `op` through the desktop app.
- Work Macs use a vault-scoped service account; loaded keys expire after nine
  hours.
- Keys are unique per machine and account, so one machine can be retired
  without rotating every other machine.
- Put only work-approved secrets, such as Flow Icons, in a work-readable vault.

Details: [GitHub credentials](docs/credentials.md) ·
[application secrets](docs/secrets.md).
