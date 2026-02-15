# Braden's Dotfiles

[![CI](https://github.com/Braden1996/dotfiles/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/Braden1996/dotfiles/actions/workflows/ci.yml)

Managed with [chezmoi](https://chezmoi.io). macOS-first, with multi-machine and architecture-aware templating.

## Quick Start

```bash
chezmoi init --apply Braden1996
```

## What's Included

| Category | Tools |
|----------|-------|
| **Shell** | zsh, antidote, starship prompt, fzf, zoxide, atuin, bat, eza, yazi |
| **Editor** | cursor (primary), neovim, zed |
| **Terminal** | ghostty, alacritty, iterm2 |
| **Git** | gpg signing, conditional work includes, aliases |
| **Tmux** | tmux + TPM, dracula theme |
| **Languages** | nvm, pyenv, rbenv (all lazy-loaded) |
| **Security** | 1Password CLI integration, GPG |
| **Theme** | Catppuccin Macchiato everywhere |

## Init Prompts

On first run, chezmoi will prompt for:

| Variable | Description | Example |
|----------|-------------|---------|
| `machineType` | `personal` or `work` | `personal` |
| `gitName` | Git author name | `Braden Caldwell` |
| `personalEmail` | Personal email for git | `braden@example.com` |
| `workEmail` | Work email (work machines only) | `braden@company.com` |
| `onePasswordAccount` | 1Password account URL | `my.1password.com` |

## Structure

```
.
├── .chezmoi.toml.tmpl           # prompted config
├── .chezmoiignore               # conditional ignores
├── dot_gitconfig.tmpl            # git config (templated)
├── dot_zshrc                     # main zsh entry
├── dot_zshenv.tmpl               # zsh environment
├── dot_zsh_plugins.txt           # antidote plugin list
├── dot_tmux.conf                 # tmux config
├── run_once_before_*.sh.tmpl     # homebrew bootstrap
├── run_once_after_*.sh.tmpl      # post-apply setup
├── dot_config/
│   ├── zsh/                      # modular zsh configs (00-99)
│   ├── zed/settings.json.tmpl    # editor settings
│   ├── ghostty/config            # terminal config
│   ├── starship.toml             # prompt theme
│   ├── nvim/init.vim             # neovim config
│   ├── atuin/config.toml         # shell history
│   └── ...
├── private_Library/
│   └── .../Cursor/User/          # cursor settings & keybindings
└── private_dot_ssh/config        # SSH config
```

## Manual Steps

After `chezmoi apply`, a few things need manual setup:

1. **1Password** - sign in to your account (`op signin`)
2. **GPG key** - import your signing key and trust it
3. **Nerd Font** - install FiraCode Nerd Font (used by zed, starship)
4. **Tmux plugins** - open tmux and press `prefix + I` to install plugins
5. **Neovim plugins** - open nvim and run `:PlugInstall`

## Updating

```bash
chezmoi update
```
