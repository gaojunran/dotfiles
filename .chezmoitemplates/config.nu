use std/util "path add"

const MY_SCRIPTS = "~/.config/scripts"
const MY_BIN = "~/.config/bin"

$env.config.buffer_editor = "code"
$env.config.show_banner = false

# 🪐 Scripts

# make binaries executable in unix
if not (is-windows) {
	ls ($MY_BIN | path expand) | each { |f| chmod +x ($MY_BIN | path join $f.name) }
}

use $"($MY_SCRIPTS)/gh-search.nu" *

# Starship
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

# Zoxide
source ~/.zoxide.nu
alias cd_nushell = cd # backup
alias cd = z

# bash-env
use $"($MY_SCRIPTS)/bash-env.nu"

# 🪐 Alias/Command definitions

alias clr = clear
alias q = exit
alias r = exec nu; clr
alias o = start

# mkdir and cd into it.
def --env mc [ dir: string ] {
	mkdir $dir
	cd $dir
}

# chezmoi
alias dot = chezmoi
alias dota = dot apply -v
alias dote = code (dot source-path)
alias dotu = dot update --apply

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

# scoop
alias sc = scoop
alias sci = scoop install
alias scu = scoop update
alias scl = scoop list
alias scx = scoop uninstall
alias scs = scoop search

# ✨ uv

alias uvr = uv run
alias uvx = uv remove
# Create a Python project and cd into it.
def --wrapped --env uvn [ name: string, ...rest ] {
    mc $name
	uv init ...$rest
}
# Sync the env with pyproject.toml, requirements.txt, or simply add a package.
def --wrapped uvi [...args] {
	if ($args | length ) == 0 {
		uv sync
		if ("requirements.txt" | path exists) {
			uv pip sync requirements.txt
		}
	} else {
		uv add ...$args
	}
}
alias uvf = ruff format

# ✨ cargo

alias cg = cargo
alias cgx = cargo uninstall
# Create a new Rust project and cd into it.
def --wrapped --env cgn [ name: string, ...rest ] {
	cargo new $name ...$rest
	cd $name
}
# Sync the env with Cargo.toml, or simply add a package.
alias cgi = cargo install
alias cgb = cargo build
alias cgt = cargo test
alias cgf = cargo fmt


# ✨ pnpm

alias pn = pnpm
# Sync the env with package.json, or simply add a package.
alias pni = pnpm install
alias pnr = pnpm run
alias pnx = pnpm remove

# ✨ gradle

def --wrapped gd [...args] {
	if is-windows {
		.\gradlew.bat ...$args
	} else {
		./gradlew ...$args
	}
}
alias gdb = gd build
alias gdr = gd run
alias gdt = gd test
alias gdf = gd format

# ✨ maven

alias mvr = mvn exec:java  


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

# fastfetch
alias ff = fastfetch

# lazygit
alias g = lazygit

# Open a project in...

alias "c." = code .
alias "z." = zed .
alias "p." = pycharm .
alias "i." = idea .

# Search-and-See a file. Use fzf to fuzzy-find a file and use bat to view it.
def ss [file: string = ""] {
	if $file == "" {
	    fzf | bat $in
	} else {
		fzf -q $file | bat $in
	}
}
