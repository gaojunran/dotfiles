# 🛠 dotfiles by gaojunran

This repo contains my dotfiles for cross-platform synchronization, which is managed by [chezmoi](https://www.chezmoi.io/).

It's opiniated😏, and you can copy some of your favourite snippets to your own dotfiles.

## If you want to match my configs exactly ❤️

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply gaojunran
```

This will install `chezmoi` and apply my dotfiles to your system. See more usages in [chezmoi](https://www.chezmoi.io/).

⚠️ My Nushell configs have tried their best to be compatible with Windows, macOS and Linux. However, I assume you have installed many cli tools in advance (see [here](https://github.com/gaojunran/dotfiles?tab=readme-ov-file#dependences-setup)), otherwise you can't use many custom commands and aliases.

## From a brand new computer 💻

1. Install **scoop** on Windows, or **brew** on macOS and Linux.

```bash
# Use Windows Terminal to install scoop
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# Install homebrew/linuxbrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Run `scoop install chezmoi nushell` or `brew install chezmoi nushell`.
3. Run `chezmoi init --apply gaojunran` to apply my dotfiles to your system.
4. Run `setup-deps` in `nushell` to install all dependencies!

## Nushell

In the year 2025, I decided to switch my workflow to [nushell](https://www.nushell.sh/). Nearly all my handful tools are nushell-related, stored [here](./.chezmoitemplates/). Here lists some scripts which are specifically separated out:

- [gh-search.nu](./dot_config/scripts/gh-search.nu): The easiest way to search or clone a repo from GitHub.
- (Currently deprecated) [nix.nu](./dot_config/scripts/nix.nu): From the project [nix-nushell-env](https://github.com/AntKazakovv/nix-nushell-env), a nushell plugin to launch nix-shell.
- [bash-env.nu](./dot_config/scripts/bash-env.nu): From the project [bash-env-nushell](https://github.com/tesujimath/bash-env-nushell), a nushell plugin to launch bash shell and load env variables from bash.

Moreover, for compatibility consideration, I will not write bash/zsh/powershell/bat scripts in the future. Python3 for simple users and Nushell for myself are enough.

## Yazi

A TUI file manager, see [here](./dot_config/yazi).

My keymap: [here](./dot_config/yazi/keymap.toml).

## Terminal

For MacOS, I use [ghostty](./dot_config/ghostty/config) as my terminal emulator. It's highly recommended to bind a hotkey `ctrl+space` to launch it.

I'm not sure what to use for Windows❓, maybe I'll wait until ghostty's Windows support.

## Keymaps (MacOS)

These keymaps are scattering everywhere, so I simply write them down here.

- `ctrl + space`: to launch search-bar in many apps, such as Finder, Arc, VS Code, Intellij Idea...
- `Caps Lock` (re-mapped to `ctrl + cmd + opt + z`): to toggle quick terminal.
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

## IDE Configurations

TODO

## Dependences Setup

My manifests for system dependences are listed below:

- [**brew**](./dot_config/setup/brew-deps): for MacOS & Linux.
- [**scoop**](./dot_config/setup/scoop-deps.json): for Windows.

Run `setup-deps` in nushell to install all dependences!

## Applications Setup

My applications, which usually called `casks` in `brew`, or `extra` in `scoop`, are listed below: 

- [**brew**](./dot_config/setup/brew-apps): for MacOS.
- [**scoop**](./dot_config/setup/scoop-apps.json): for Windows.

Run `setup-apps` in nushell to install all applications!