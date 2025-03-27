use std/util "path add"

const MY_SCRIPTS = "~/.config/scripts"
const MY_BIN = "~/.config/bin"

$env.config.buffer_editor = "code"
$env.config.show_banner = false
$env.EDITOR = "code"

# 🪐 Scripts

# make binaries executable in unix
if not (is-windows) {
	ls ($MY_BIN | path expand) | each { |f| chmod +x ($MY_BIN | path join $f.name) }
}

use $"($MY_SCRIPTS)/gh-actions.nu" *

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
# zoxide
alias cd = z  
alias q = exit
alias cat = bat
alias cpp = cp
alias cp = cb copy
alias degit = tiged
alias ts = tailscale
alias ff = fastfetch
alias g = lazygit
# bottom, to monitor system stats
alias top = btm
# https://github.com/antfu/iroiro, to pick colors
alias iro = npx iroiro
# Switch between mac/win and arch linux
alias mac = mac nu
# alias win = C:\Users\gaoju\scoop\apps\nu\current\nu.exe
def arch [] {
	if (is-windows) {
		Arch.exe runp "nu"
	} else {
		orb nu
	}
}

# cd to my directories
alias hw = cd ~/Homework
alias py = cd ~/py-projects
alias rs = cd ~/rs-projects
alias vue = cd ~/vue-projects

# usql actions
def pg [db?: string] {
	if $db == null {
		usql "pg://nebula:nebula@localhost:5432/"
	} else {
		usql ("pg://nebula:nebula@localhost:5432/" + $db)
	}
}

# pick a project using fzf, and cd into it (by default).
def --env pro [] {
	# TODO
}


# mkdir and cd into it.
def --env mc [ dir: string ] {
	mkdir $dir
	if ("justfile" | path exists) {
		cp "justfile" ($dir | path join "justfile")
	}
	cd $dir
}

def new [suffix: string, ...rest] {
	for $name in $rest {
	  touch ($name + "." + $suffix)
		print ("Created " + $name + "." + $suffix)
	}
}

# clear and refresh shell
def r [] {
	clear
	exec nu
}

# chezmoi
alias dot = chezmoi
alias dota = dot apply -v
alias dote = code (dot source-path)
alias dotu = dot update --apply

# just
alias j = just
# Run a global command.
alias jg = just --justfile ~/.config/justfile --working-directory .
alias d = just dev
alias jr = just run
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
alias cgi = cargo add
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
alias mvc = mvn clean

# Use llm with aichat
alias "？" = aichat
alias ai = aichat
# execute shell command with aichat
alias aix = aichat -e
# get code only with aichat
alias aic = aichat -c
alias trans = aichat "Translate to Chinese if it's English, and Translate to English if it's Chinese. If it's a word, try to give me its meanings as many as possible: "


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
# Open in HOME and do not change cwd when quitting. Often used for searching files.
alias yy = yazi ~
alias yd = y ~/Downloads
alias yc = y ~/.config
alias yD = y ~/Documents
alias ys = y ~/Pictures/Screenshots
alias yp = y ~/Playground


# use code to open in pwd, or open a dir.
def c [ arg?: string ] {
  if $in == null and $arg == null {
		code .
	} else if $arg == null {
		code $in
	} else {
		code $arg
	}
}

# use idea to open in pwd, or open a dir.
def i [ arg?: string ] {
  if $in == null and $arg == null {
		idea .
	} else if $arg == null {
		idea $in
	} else {
		idea $arg
	}
}



# use finder to open in pwd, or open a dir.
def o [ arg?: string ] {
	if $in == null and $arg == null {
		start .
	} else if $arg == null {
		start $in
	} else {
		start $arg
	}
}

# Find help from `<command> --help`.
def "?" --wrapped [
	...cmd
] {
	nu -l -c (($cmd | str join " ") +  " --help")
}





# 📢 Install all dependences. See https://github.com/gaojunran/dotfiles?tab=readme-ov-file#dependences-setup.
def "setup-deps" [] {
	if (is-windows) {
		scoop import ~/.config/setup/scoop-deps.json
	} else if (is-macos) {
		brew bundle --file ~/.config/setup/brew-deps
	} else {
		"Use your own package manager bro! TODO: yay's automation"
	}
}

# 📢 Install all applications. See https://github.com/gaojunran/dotfiles?tab=readme-ov-file#applications-setup.
def "setup-apps" [] {
	if (is-windows) {
		scoop import ~/.config/setup/scoop-apps.json
	} else if (is-macos) {
		brew bundle --file ~/.config/setup/brew-apps
	} else {
		"Do you want to use GUI apps in Linux? Anyway, I don't."
	}
}

# 📢 Run once when coming to a new machine. Prepare all the directories.
def "setup-dirs" [] {
	mkdir -v ~/Downloads
	mkdir -v ~/Documents
	mkdir -v ~/Pictures
	mkdir -v ~/Videos
	mkdir -v ~/Music
  # For temporary projects.
	mkdir -v ~/Playground   
	# My projects.
	# Only receive softlinks from different language folders to this folder.
	mkdir -v ~/Projects
	mkdir -v ~/vue-projects
	mkdir -v ~/rs-projects
	mkdir -v ~/py-projects
	mkdir -v ~/jvm-projects
}
