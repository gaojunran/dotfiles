use std/util "path add"

const MY_SCRIPTS = "~/.config/scripts"


# 🪐 Scripts

source $"($MY_SCRIPTS)/gs.nu"

# Starship
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

# Zoxide
source ~/.zoxide.nu
alias cd_nushell = cd # backup
alias cd = z

# 🪐 Alias/Command definitions

alias clr = clear
alias q = exit
alias r = exec nu; clr
alias o = start

# chezmoi
alias dot = chezmoi
alias dota = dot apply -v
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

# homebrew
alias br = brew
alias bri = brew install
alias bru = brew upgrade
alias brl = brew list
alias brx = brew uninstall
alias brs = brew search

# yazi
def --env y [...args] {
	let tmp = (mktemp -t "yazi-cwd.XXXXXX")
	yazi ...$args --cwd-file $tmp
	let cwd = (open $tmp)
	if $cwd != "" and $cwd != $env.PWD {
		cd $cwd
	}
	rm -fp $tmp
}

# zellij
alias z = zellij

# tailscale
alias ts = tailscale