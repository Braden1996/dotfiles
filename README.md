<br />
<h1 align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Terminalicon2.png/768px-Terminalicon2.png" alt="Terminal Logo" width="256">
  <br />
  Braden's Dotfiles
</h1>

<br />

<h4 align="center">Almost certainly out-of-date.</h4>

<p align="center">
  <a href="https://github.com/Braden1996/dotfiles">
    <img alt="GitHub" src="https://img.shields.io/badge/%20-GitHub-7158e2.svg?style=for-the-badge&logo=github&logoColor=f8f8f2&colorA=1C2431" />
  </a>
</p>

## Table of Contents 📚

- [Introduction](#introduction-)
- [Installation](#installation-)
- [Applications](#applications-)
  - [Quality of Life](#quality-of-life-)
  - [Development](#development-)
    - [iOS](#ios-)
    - [Android](#android-)
- [Shell](#shell-)

## Introduction 💪

A notepad primarily aimed at reminding myself how to ~cook my porridge~ setup my machine just the way I like it. Aimed for MacOS, but some support for WSL.

Includes favorite applications, dot-files, shell tools etc...

## Installation 👨🏼‍💻

1. Install Command Line Tools: `sudo xcode-select --install`
1. Install Brew package manager: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
1. Install YADM and clone this repo: https://yadm.io/docs/install#freebsd
1. Setup SSH key with GitHub: [Generating a new SSH key and adding it to the ssh-agent](https://docs.github.com/en/github-ae@latest/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
1. Follow Terminal instructions in [Development](#development-)


## Applications 🎁

### Quality of Life 🌅

- Browser - Brave: `brew install brave-browser`
- Password Manager - 1Password: `brew install 1password`
- Spotlight - Raycast: `brew install raycast`
- System Monitor - iStat Menus: `brew install istat-menus`
- Menu Bar - Bartender: `brew install bartender`
- Screenshots - Cleanshot: `brew install cleanshot`
- Colour Picker - Sip: `brew install homebrew/cask/sip`
- Window Manager - Magnet: [Download from App Store](https://apps.apple.com/gb/app/magnet/id441258766?mt=12)
- Email - Spark: [Download from App Store](https://apps.apple.com/gb/app/spark-email-app-by-readdle/id1176895641?mt=12)
- Photo Editor - Affinity Photo: [Download from App Store](https://apps.apple.com/gb/app/affinity-photo/id824183456?mt=12)
- Graphic Editor - Affinity Designer: [Download from App Store](https://apps.apple.com/gb/app/affinity-designer/id824171161?mt=12)
- Digital Media - Adobe: `brew install adobe-creative-cloud`
- Media Player - Plex: `brew install plex`
- Splash Screen - Brooklyn: `brew install brooklyn`

### Development 🏗

- Font - JetBrains Mono Nerd font: `brew install homebrew/cask-fonts/font-jetbrains-mono-nerd-font`
- Terminal - Alacritty: `brew install alacritty`
- Terminal - iTerm2: `brew install iterm2`
  - [Git Clone Dracula theme](https://draculatheme.com/iterm)
  - Configure font, transparency and blur.
  - `.config/iterm2/Default.json` can be loaded in.
- Editor - Visual Studio Code: `brew install visual-studio-code`
    - Settings [synced via GitHub](https://code.visualstudio.com/docs/editor/settings-sync).
- Mobile Debugger - Flipper: `brew install flipper`

#### iOS 🍎

1. Install Xcode: [Download from App Store](https://apps.apple.com/gb/app/xcode/id497799835?mt=12)
1. Install Cocoapods: `sudo gem install cocoapods`
  - For M1 ARM macs:
    - `sudo arch -x86_64 gem install ffi`
    - `arch -x86_64 pod install`

#### Android 🤖

1. Install Java8: `brew install adoptopenjdk/openjdk/adoptopenjdk8`
1. Install Android Studio: `brew install android-studio`
1. Open Android Studio, then choose `Preferences...` from the menu bar. Go to `Appearance & behaviour` -> `System Settings` -> `Android SDK`. From here, select and install the following:
    1. `SDK Platforms` tab.
        1. `Android 9.0 (Pie)`
    1. `SDK Tools` tab.
        1. `Android SDK Command-line Tools (latest)`
        1. `Android Emulator`
        1. `Android SDK Platform-Tools`
        1. `Intel x86 Emulator Accelerator (HAXM installer)`
        1. (`.zshrc` exports `ANDROID_HOME` and amends `PATH`)
1. Sign soul away: `sdkmanager --licenses`

## Shell 🐚

  - Shell - ZSH: `brew install zsh`
  - Plugin Manager - Antigen: `brew install antigen`
    - Currently missing latest M1 build. Track issue [Add macOS ARM builds to CI](https://github.com/alacritty/alacritty/pull/4727)
  - Prompt Theme - Starship: `brew install starship`
  - Session Manager - Tmux: `brew install tmux`
    - Plugin Manager - TPM: `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
      - Fire install command: https://github.com/tmux-plugins/tpm#installing-plugins
  - Editor - Neovim: `brew install neovim`
      - Install [vim-plug for Neovim](https://github.com/junegunn/vim-plug#unix-linux):
        ```
          sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
                https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
        ```
  - List Command - EXA: `brew install exa`
  - File Explorer - Ranger: `brew install ranger`
  - Fuzzy CD - Autojump: `brew install autojump`
  - Python Environments - Pyenv: `brew install pyenv`
  - Ruby Environments - Rbenv: `brew install pyenv`
  - Node Environments - FNM: `brew install fnm`
    - Install node version: `fnm install 16.6.0`
  - Node Package Manager - Yarn: `brew install yarn`
    - Install node version: `fnm install 16.6.0`
  - GitHub SSH key:
    - See [Generating a new SSH key and adding it to the ssh-agent](https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh)

<br />

<img alt="Fuck it, ship it" src="https://forthebadge.com/images/badges/fuck-it-ship-it.svg" align="right" />
