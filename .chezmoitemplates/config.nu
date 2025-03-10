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
if (is-installed "starship") {
	starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
}

# Zoxide
source ~/.zoxide.nu # Why can't I wrap it by if?

# bash-env
use $"($MY_SCRIPTS)/bash-env.nu"

# 🪐 Alias/Command definitions
alias cd = z  # zoxide
alias q = exit
alias r = clear; exec nu
alias cat = bat
alias degit = tiged
alias ts = tailscale
alias ff = fastfetch
alias g = lazygit

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

# brew for MacOS
alias br = brew
alias bri = brew install
alias bru = brew upgrade
alias brl = brew list
alias brx = brew uninstall
alias brs = brew search

# scoop for Windows
alias sc = scoop
alias sci = scoop install
alias scu = scoop update
alias scl = scoop list
alias scx = scoop uninstall
alias scs = scoop search

# yay of Arch Linux
alias ya = yay 
alias yai = yay -S
alias yau = yay -S
alias yal = yay -Q
alias yax = yay -Rs
alias yas = yay -Ss

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
# Use wrapper if exists, otherwise use gradle directly (often to init a new project).
def --wrapped gd [...args] {
	if (is-windows) and ("./gradlew.bat" | path exists) {
		.\gradlew.bat ...$args
	} else if ("./gradlew" | path exists) {
		./gradlew ...$args
	} else {
		gradle ...$args
	}
}
# Create a Gradle project and cd into it.
def --wrapped --env gdn [ name: string, ...rest ] {
    mc $name
	gd init ...$rest
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

# use code to open in pwd, or open a dir.
def c [ dir?: string ] {
    if $dir == null {
		code .
	} else {
		code $dir
	}
}

# use idea to open in pwd, or open a dir.
def i [ dir?: string ] {
    if $dir == null {
		idea .
	} else {
		idea $dir
	}
}

# start
def o [ arg?: string ] {
    if $arg == null {
		start .
	} else {
		start $arg
	}
}


# Search-and-See a file. Use fzf to fuzzy-find a file and use bat to view it.
def ss [file?: string] {
	if $file == null {
	    fzf | bat $in
	} else {
		fzf -q $file | bat $in
	}
}

# Find help from `<command> --help`.
def "?" --wrapped [
	...cmd
] {
	nu -l -c (($cmd | str join " ") +  " --help")
}

# Find help from tldr.
alias "??" = tldr


# Install all dependences. See https://github.com/gaojunran/dotfiles?tab=readme-ov-file#dependences-setup.
def "setup-deps" [] {
	if (is-windows) {
		scoop import ~/.config/setup/scoop-deps.json
	} else if (is-macos) {
		brew bundle --file ~/.config/setup/brew-deps
	} else {
		"Use your own package manager bro!"
	}
}

# Install all applications. See https://github.com/gaojunran/dotfiles?tab=readme-ov-file#applications-setup.
def "setup-apps" [] {
	if (is-windows) {
		scoop import ~/.config/setup/scoop-apps.json
	} else if (is-macos) {
		brew bundle --file ~/.config/setup/brew-apps
	} else {
		"Do you want to use GUI apps in Linux? Anyway, I don't."
	}
}