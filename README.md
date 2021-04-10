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

## Introduction 💪

My dotfiles, and go-to applications, for a hasty and more consistent multi-system setup.


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

- Terminal - Alacritty: `brew install alacritty`
    1. Install ZSH: `brew install zsh`
    1. Install tmux (session manager): `brew install tmux`
    1. Install JetBrains Mono Nerd font: `brew install homebrew/cask-fonts/font-jetbrains-mono-nerd-font`
    1. Install Starship prompt: `brew install starship`
    1. Install Antigen ZSH plugin manager: `brew install antigen`
    1. Install Neovim editor: `brew install neovim`
    1. Install Exa (better `ls` command): `brew install exa`
    1. Install Ranger (CLI file-explorer): `brew install ranger`
    1. Install Autojump (fuzzy `cd` command): `brew install autojump`
    1. Install Pyenv (manage Python environments): `brew install pyenv`
    1. Install Rbenv (manage Ruby environments): `brew install rbenv`
    1. Install nvm (manage Node environments): `brew install nvm`
        - Install long-term-support version: `nvm install --lts`
- Git Signing - Krypton: `curl https://krypt.co/kr | sh`
    1. Doesn't work on latest Macos :(
    1. Pair `kr` with Krypton mobile device: `kr pair`
    1. Upload key to GitHub: `kr github`
- Git Signing - GnuPG2: `brew install gnupg2`
    1. Does not work on Mac M1: [libgcrypt Mac M1 build fix proposal](https://dev.gnupg.org/D522)
    1. Tell Git to use GPG2: `git config --global gpg.program gpg2`
    1. [Follow instructions here](https://docs.github.com/en/github/authenticating-to-github/signing-commits).
- Editor - Visual Studio Code: `brew install visual-studio-code`
    - Settings [synced via GitHub](https://code.visualstudio.com/docs/editor/settings-sync).
- Mobile Debugger - Flipper: `brew install flipper`

#### iOS 🍎

1. Install Xcode: [Download from App Store](https://apps.apple.com/gb/app/xcode/id497799835?mt=12)
1. Install Cocoapods: `sduo gem install cocoapods`

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

<br />

<img alt="Fuck it, ship it" src="https://forthebadge.com/images/badges/fuck-it-ship-it.svg" align="right" />
