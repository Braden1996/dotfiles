<p align="center">
  <img src="assets/banner.png" alt="Braden's Dot Files" width="100%" />
</p>

<p align="center">
  <a href="https://github.com/Braden1996/dotfiles/actions/workflows/ci.yml"><img src="https://github.com/Braden1996/dotfiles/actions/workflows/ci.yml/badge.svg?branch=master" alt="CI" /></a>
  <a href="https://www.chezmoi.io/"><img src="https://img.shields.io/badge/managed%20with-chezmoi-blue?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABGdBTUEAALGPC/xhBQAAAAlwSFlzAAAOwgAADsIBFShKgAAAABl0RVh0U29mdHdhcmUAcGFpbnQubmV0IDQuMC4xMkMEa+wAAALzSURBVFhH7ZVfSFNRHMfPuf+2e527u5pm4pyi5r+0P2amkdqDPfRQUBA99BBFBBJE0ENQD0FBDxH0EEHRQxBBDz0EEUR/KCKxP2plZaalZmpuc3N3t3t37t09945tOrfmQ0Tf4eOc3z2/3+97zj33Xor+RyD/CuAXgMfjuUqS5EWKou6jKGq7uq4xRqNxllar7dRoNIdJkjwEoFW3NgBJkjPALi/lm/1+f7vL5XpGfV6ySZyOEI8bOBWq/UMRVEbNnWfpumVRqPxqE6n22ez2a5RFHVQXRZAEAS/JEl9fr+/1ev17qbe8sVMC+gIguBomq40m80nDAZDB0EQVdLS6LcMwwx4PJ7nHo/nPvV6IcZpwRMIBF66XK5blNP5gJFWfAy4a7FYOo1G41mSJOvkJwBCLMuOuN3uh263+5akKKhDoH6YO6Cy+gZxr8tms922Wq0d8jKiEDzHjbnd7kcul+smdYF7x8v0gWBw0u/3v3S73Q+oN/wYp0UBxJlP+3w+AYi7FEWdQf//5fV6h51O53uHw/GGekC/FxjGhX0Bh8NxraCg4GJFRUW7TqfbhM+4LvZ8Nm63+wXu41sWi6VbvkAE0DTNK0bwBDxvNZvNl4uLiy/k5OQ0SSGE3DjAMEy/0+l84nQ6H1N9fCfnkz7x4UbFYPBaXl5eW0FBwUWz2bxPWZw1+G7+1mKx3KJelncpJRWAyIciETsOhAOBwC8ZZnB8fPyx1Wr9k4rYbsiyH8Trnf8B6L3e22fE15JcBGhJjuO4oUAg0OfxeHoWL17cNmfOnAsZGRl1CMHjOMBx3LjP57s/NjZ2i+rjB+Xz0D7pJRfLPcR9TrdDsCWDZnNmZuYFo9F4Gp9zOEDZjIO4Z8Dtdt8eGxu7S/XyY/LVUGepIXkEiHPUbPRdfLhpvV5/ICUl5TRBEBU4gO/N3+DzdGIeeWVOkf7EF8IVhN9FHiCv+Bj5RHUmk4EupqWlnTYYDOdwU/b7J4A/wLb9G6D9BjAbx3rEbxFDAAAAAElFTkSuQmCC" alt="chezmoi" /></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey?logo=apple" alt="macOS" />
  <img src="https://img.shields.io/badge/shell-zsh-green?logo=gnubash" alt="zsh" />
  <img src="https://img.shields.io/badge/theme-Catppuccin%20Macchiato%20%2F%20Dracula-mauve?logo=catppuccin&logoColor=cba6f7" alt="Catppuccin Macchiato / Dracula" />
</p>

---

### Quick Start

```bash
chezmoi init --apply Braden1996
```

### What's Included

<table>
<tr><td><b>Shell</b></td><td>zsh, antidote, starship prompt, fzf, zoxide, atuin, bat, eza, yazi</td></tr>
<tr><td><b>Editor</b></td><td>cursor (primary), neovim, zed</td></tr>
<tr><td><b>Terminal</b></td><td>ghostty, alacritty, iterm2</td></tr>
<tr><td><b>Git</b></td><td>gpg signing, graphite, conditional work includes, aliases</td></tr>
<tr><td><b>Tmux</b></td><td>tmux + TPM, dracula theme</td></tr>
<tr><td><b>Files</b></td><td>yazi (Ctrl+y picker), ranger</td></tr>
<tr><td><b>Languages</b></td><td>nvm, pyenv, rbenv (all lazy-loaded), bun</td></tr>
<tr><td><b>Security</b></td><td>1Password CLI (<code>op://</code> URIs), GPG commit signing, atuin secrets filter</td></tr>
<tr><td><b>Theme</b></td><td>Catppuccin Macchiato (ghostty, zed, starship, fzf, fsh) / Dracula (alacritty, iterm2, nvim, tmux)</td></tr>
</table>

### Highlights

<details>
<summary><b>Lazy-loaded version managers</b></summary>
<br/>
NVM, pyenv, and rbenv are wrapped so they only initialize when first called. NVM also auto-switches Node versions when you <code>cd</code> into a directory with an <code>.nvmrc</code>.
</details>

<details>
<summary><b>Work / personal machine branching</b></summary>
<br/>
Set <code>machineType</code> at init to toggle work-specific git configs (separate signing key, email, conditional includes for work repos). Architecture-aware paths handle Apple Silicon vs Intel Homebrew locations.
</details>

<details>
<summary><b>Starship prompt</b></summary>
<br/>
Full Catppuccin Macchiato palette, rune character (<code>ᛃ</code>) for success/error/vim mode indicators, git state detection (rebase, cherry-pick, merge, bisect), directory icons via Nerd Font substitutions, and right-aligned command duration + clock.
</details>

<details>
<summary><b>FZF everywhere</b></summary>
<br/>
Catppuccin colors, bat-powered preview windows, fzf-tab for completions, Ctrl+R history with a 60% preview panel, and magic-enter integration (Cmd+Enter for git status or directory listing).
</details>

<details>
<summary><b>Git aliases</b></summary>
<br/>
<code>shit</code> (amend), <code>fuck</code> (amend + force push), <code>nuke</code> (reset --hard + clean), <code>ignore</code> (append to .gitignore), <code>ls</code> / <code>ll</code> (compact log formats).
</details>

<details>
<summary><b>Antidote plugin loading</b></summary>
<br/>
Core: zephyr (prompt, completion). Oh-My-Zsh: git, magic-enter, extract, sudo. Deferred: autosuggestions, autopair, you-should-use, forgit, fast-syntax-highlighting. Atomic bundle regeneration prevents race conditions.
</details>

<details>
<summary><b>1Password integration</b></summary>
<br/>
<code>op://</code> URIs in templated configs for secrets, CLI completion hooks in zsh, and GPG signing key storage.
</details>

<details>
<summary><b>CI pipeline</b></summary>
<br/>
Template validation via chezmoi, shellcheck linting (SC1090/SC1091 excluded), JSON validation for editor configs, and automatic PR labeling by area (shell, git, editor, terminal, tmux, chezmoi).
</details>

<details>
<summary><b>Dependency checker</b></summary>
<br/>
Run <code>zsh-check-deps</code> to verify required tools (starship, fzf) and optional ones (eza, bat, yazi, zoxide, antidote) with color-coded output and install hints.
</details>

### Init Prompts

On first run, chezmoi will prompt for:

| Variable | Description | Example |
|----------|-------------|---------|
| `machineType` | `personal` or `work` | `personal` |
| `gitName` | Git author name | `Braden Marshall` |
| `personalEmail` | Personal email for git | `braden@example.com` |
| `workEmail` | Work email (work machines only) | `braden@company.com` |
| `onePasswordAccount` | 1Password account URL | `my.1password.com` |

### Structure

```
.
├── .chezmoi.toml.tmpl              # prompted config
├── .chezmoiignore                  # conditional ignores
├── dot_gitconfig.tmpl              # git config (templated)
├── dot_attio.gitconfig             # work-specific git config
├── dot_zshrc                       # main zsh entry
├── dot_zshenv.tmpl                 # zsh environment
├── dot_zprofile                    # login shell setup
├── dot_zsh_plugins.txt             # antidote plugin list
├── dot_tmux.conf                   # tmux config
├── dot_fzf.settings                # fzf defaults
├── dot_bashrc                      # bash fallback
├── dot_profile                     # POSIX profile
├── empty_dot_hushlogin             # suppress login banner
├── run_once_before_*.sh.tmpl       # homebrew bootstrap
├── run_once_after_*.sh.tmpl        # post-apply setup
├── dot_config/
│   ├── zsh/                        # modular zsh configs (00-99)
│   │   ├── 00-path.zsh             #   PATH management
│   │   ├── 10-options.zsh          #   shell options & history
│   │   ├── 20-plugins.zsh          #   antidote + starship init
│   │   ├── 30-completion.zsh       #   fzf-tab, bookmarks
│   │   ├── 40-tools.zsh            #   lazy nvm/pyenv/rbenv
│   │   ├── 50-functions.zsh.tmpl   #   yazi, nx wrapper
│   │   ├── 70-keybindings.zsh      #   Ctrl+y, arrow keys
│   │   └── 99-local.zsh.tmpl       #   machine-specific
│   ├── zed/settings.json.tmpl      # zed editor (biome, catppuccin)
│   ├── ghostty/config              # ghostty (catppuccin, blur)
│   ├── alacritty/alacritty.yml     # alacritty (dracula)
│   ├── iterm2/Default.json         # iterm2 profile
│   ├── starship.toml               # prompt (catppuccin palette)
│   ├── nvim/init.vim               # neovim (dracula, plug)
│   ├── atuin/config.toml           # shell history sync
│   ├── fsh/                        # fast-syntax-highlighting theme
│   ├── ranger/                     # file manager + devicons
│   ├── graphite/aliases            # git stacking aliases
│   └── private_git/                # private git ignores
├── private_Library/
│   └── .../Cursor/User/            # cursor settings & keybindings
└── private_dot_ssh/config          # SSH (ed25519, keychain)
```

### Manual Steps

After `chezmoi apply`, a few things need manual setup:

1. **1Password** - sign in to your account (`op signin`)
2. **GPG key** - import your signing key and trust it
3. **Nerd Font** - install FiraCode Nerd Font (used by zed, starship)
4. **Tmux plugins** - open tmux and press `prefix + I` to install plugins
5. **Neovim plugins** - open nvim and run `:PlugInstall`

### Updating

```bash
chezmoi update
```
