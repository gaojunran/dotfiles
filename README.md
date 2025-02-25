# 🛠 dotfiles by gaojunran

This repo contains my dotfiles for cross-platform synchronization, which is managed by [chezmoi](https://www.chezmoi.io/).

It's opiniated😏, and you can copy some of your favourite snippets to your own dotfiles.

## If you want to match my configs exactly ❤️

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply gaojunran
```

This will install `chezmoi` and apply my dotfiles to your system. See more usages in [chezmoi](https://www.chezmoi.io/).

⚠️ My Nushell configs have tried their best to be compatible with Windows, macOS and Linux. However, I assume you have installed many cli tools in advance, otherwise you can't use many custom commands and aliases.


## Nushell

In the year 2025, I decided to switch my workflow to [nushell](https://www.nushell.sh/). Nearly all my handful tools are nushell-related, stored [here](./.chezmoitemplates/). Here lists some scripts which are specifically separated out:

- [gh-search.nu](./dot_config/scripts/gh-search.nu): The easiest way to search or clone a repo from GitHub.
- (Currently deprecated) [nix.nu](./dot_config/scripts/nix.nu): From the project [nix-nushell-env](https://github.com/AntKazakovv/nix-nushell-env), a nushell plugin to launch nix-shell.
- [bash-env.nu](./dot_config/scripts/bash-env.nu): From the project [bash-env-nushell](https://github.com/tesujimath/bash-env-nushell), a nushell plugin to launch bash shell and load env variables from bash.

Moreover, for compatibility consideration, I will not write bash/zsh/powershell/bat scripts in the future. Python3 for simple users and Nushell for myself are enough.

## Yazi

A TUI file manager, see [here](./dot_config/yazi).

## Dependences Setup

My manifests for system dependences are listed below:

- [**brew**](./dot_config/brew-deps): for MacOS.
- [**scoop**](./dot_config/scoop-deps.json): for Windows.
- **apt**: for Ubuntu Linux. Working.

Run `just deps-setup` in `HOME` to install all dependences!

## Applications Setup

My applications, which usually called `casks` in `brew`, or `extra` in `scoop`, are listed below: 

- [**brew**](./dot_config/brew-apps): for MacOS.
- [**scoop**](./dot_config/scoop-apps.json): for Windows.
- **apt**: for Ubuntu Linux. Working.

Run `just apps-setup` in `HOME` to install all applications!