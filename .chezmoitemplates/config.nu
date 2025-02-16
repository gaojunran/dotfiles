use std/util "path add"

const MY_SCRIPTS = "~/.config/scripts"

# Mac OS only:
path add "/opt/homebrew/opt/openjdk@21/bin"
# path add "/opt/homebrew/bin"
path add "/opt/homebrew/anaconda3/bin"
path add "~/.cargo/bin"
path add "~/Library/Application Support/JetBrains/Toolbox/scripts"

path add "~/Projects/scripts"


$env.config.buffer_editor = "code"
$env.config.show_banner = false

# Starship
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

# Zoxide
source ~/.zoxide.nu

# Alias definitions

# Simple shortcuts
alias clr = clear
alias q = exit
alias r = reset

# chezmoi
alias dot = chezmoi
alias dota = chezmoi apply -v
alias dote = code (dot source-path)

# just
alias j = just
alias jr = just run
alias jd = just dev
alias jf = just fmt
alias jt = just test
alias jb = just build

# tiged
alias degit = tiged

# Command definitions

# git

source $"($MY_SCRIPTS)/gs.nu"