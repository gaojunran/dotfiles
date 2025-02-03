use std/util "path add"

# Mac OS only:
path add "/opt/homebrew/opt/openjdk@21/bin"
path add "/opt/homebrew/bin"
path add "/opt/homebrew/anaconda3/bin"
path add "~/.zsh"
path add "~/.cargo/bin"

path add "~/Projects/scripts"

$env.config.buffer_editor = "code"

$env.config.show_banner = false

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

# Alias definitions
alias dot = chezmoi
alias dota = chezmoi apply -v
alias dote = code (dot source-path)