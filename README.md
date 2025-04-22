# 🛠 dotfiles by gaojunran

This repo contains my dotfiles, managed by [chezmoi](https://www.chezmoi.io/).

It's opiniated😏, but is well-organized 🚀, so you can copy some of your favourite snippets to your own dotfiles.

## How to use 🔨

1. Install [chezmoi](https://www.chezmoi.io/) and [nushell](https://www.nushell.sh/) to your system.
2. Run `chezmoi init --apply gaojunran` to apply my dotfiles to your system.
3. Install scoop or brew, and run `setup-deps` in `nushell` to install all dependencies!

⚠️ My Nushell configs have tried their best to be compatible with Windows, macOS and Linux. However, I assume you have installed many cli tools in advance (see [here](https://github.com/gaojunran/dotfiles?tab=readme-ov-file#dependences-setup)), otherwise you can't use many custom commands and aliases.

## Features

### Nushell

In the year 2025, I decided to switch my workflow to [nushell](https://www.nushell.sh/). Nearly all my handful tools are nushell-related, stored [here](./.chezmoitemplates/). 

Moreover, for compatibility consideration, I will not write `bash/zsh/powershell/bat` scripts in the future. Python3/JavaScript for simple users and Nushell for myself are enough.

**I really ❤️ nushell!** And I have written 500-line config for it, including [git workflow](./dot_config/scripts/git.nu), [github workflow](./dot_config/scripts/gh.nu), aliases for tons of CLI tools, and so on.

### Yazi

A TUI file manager, see [here](./dot_config/yazi).

My keymap: [here](./dot_config/yazi/keymap.toml).

### Terminal

For MacOS, I use [ghostty](./dot_config/ghostty/config) as my terminal emulator. It's highly recommended to bind a hotkey `cmd+space` to launch it.

For Windows, I use [Windows Terminal](./AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json) as default.

### Keymaps (MacOS)

These keymaps are scattering everywhere, so I simply write them down here.

- `ctrl + space`: to launch search-bar in many apps, such as Finder, Arc, VS Code, Intellij Idea...
- `Caps Lock`: to toggle quick terminal.
- `cmd + shift + s`: Screenshot or Record, by Cleanshot.
- Keymaps which are managed by Raycast:
  - `opt + space`: to toggle Raycast.
  - `cmd + space`: to toggle Terminal (Ghostty).
  - `opt + a`: Toggle Arc.
  - `opt + w`: Toggle Wechat.
  - `opt + q`: Toggle QQ.
  - `opt + f`: Search for files.
  - `opt + t`: Quickly translate.
  - `opt + s`: Search for snippets.
  - `opt + v`: Search in clipboard.
  - `opt + z`: Search for menu items.

### IDE Configurations

- [VS Code](./.chezmoitemplates/vscode-settings.json): My VS Code settings. Extends from [antfu's](https://github.com/antfu/vscode-settings/blob/main/.vscode/settings.json). Focusing on Rust, Python and Web development.

### Justfiles

My justfiles are stored [here](./dot_config/templates/), which are handful language-related recipes for the CLI tool [just](https://github.com/casey/just).

### Password Management

As I have Windows devices, Android devices, it's hard for me to use Apple's keyring.

I choose [Bitwarden](https://bitwarden.com/) as my password manager.

I've heard from that [VaultWarden](https://github.com/dani-garcia/vaultwarden) is a self-hosted, Rust-based Bitwarden server, and I'll try it in the future.

### Dependences Setup

My manifests for system dependences are listed below:

- [**brew dependences for MacOS**](./dot_config/setup/brew-deps): for MacOS.
- [**scoop dependences for Windows**](./dot_config/setup/scoop-deps.json): for Windows.
- for Linux? Use your favourite package manager!

Run `setup-deps` in nushell to install all dependences!

### Applications Setup

My applications, which usually called `casks` in `brew`, or `extras` in `scoop`, are listed below: 

- [**brew applications for MacOS**](./dot_config/setup/brew-apps).
- [**scoop applications for Windows**](./dot_config/setup/scoop-apps.json).
- for Linux? Are you sure to use GUI apps in Linux? I don't want!

Run `setup-apps` in nushell to install all applications!

## Blog

https://codenebula.netlify.app

## LISENSE

**MIT**. You can do anything with my dotfiles, and it's better if you share them with others.
