# 🛠 dotfiles by gaojunran

This repo contains my dotfiles for cross-platform synchronization, which is managed by [chezmoi](https://www.chezmoi.io/).

It's opiniated😏, and you can copy some of your favourite snippets to your own dotfiles.

## If you want to match my configs exactly ❤️

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply gaojunran
```

This will install `chezmoi` and apply my dotfiles to your system. See more usages in [chezmoi](https://www.chezmoi.io/).

## nushell

In the year 2025, I decided to switch my workflow to [nushell](https://www.nushell.sh/). Nearly all my handful tools are nushell-related, stored [here](./.chezmoitemplates/). Here lists some scripts which arespecifically separated out:

- [gs.nu](./dot_config/scripts/gs.nu): The easiest way to search or clone a repo from GitHub.
- ...




