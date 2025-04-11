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

# Starship
mkdir ($nu.data-dir | path join "vendor/autoload")
if (is-installed "starship") {
	starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
}

# Zoxide
source ~/.zoxide.nu # Why can't I wrap it by if?

# bash-env
use $"($MY_SCRIPTS)/bash-env.nu"

# asdf
let shims_dir = (
  if ( $env | get --ignore-errors ASDF_DATA_DIR | is-empty ) {
    $env.HOME | path join '.asdf'
  } else {
    $env.ASDF_DATA_DIR
  } | path join 'shims'
)
$env.PATH = ( $env.PATH | split row (char esep) | where { |p| $p != $shims_dir } | prepend $shims_dir )
source ~/.asdf/plugins/java/set-java-home.nu

# ----------------------------

# 🪐 Alias/Command definitions
# zoxide
def --env cd [ dir?: string ] {
	if ($dir == null) {
		z
	} else {
		z $dir
	}
	if (("justfile" | path exists) and (open "justfile" | find "cd:" | length) > 0) {
		just cd
	}
}
alias cdp = cd ~/Playground

alias q = exit
alias cat = bat
alias degit = tiged
alias ts = tailscale
alias ff = fastfetch
alias g = lazygit
# bottom, to monitor system stats
alias top = btm
# https://github.com/antfu/iroiro, to pick colors
alias iro = npx iroiro
alias hex = hexyl
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

# Find help from `<command> --help`.
def "?" --wrapped [
	...cmd
] {
	nu -l -c (($cmd | str join " ") +  " --help")
}

def gitignore [ category: string ] {
	curl -o .gitignore 'https://raw.githubusercontent.com/github/gitignore/refs/heads/main/' + $category + '.gitignore'
}

def mix [] {
	repomix
	cb copy ./repomix-output.txt
}

# usql actions
def pg [db?: string] {
	if $db == null {
		usql "pg://nebula:nebula@localhost:5432/"
	} else {
		usql ("pg://nebula:nebula@localhost:5432/" + $db)
	}
}

# mkdir and cd into it.
def --env mc [ dir: string ] {
	mkdir $dir
	if ("justfile" | path exists) {
		!cp "justfile" ($dir | path join "justfile")
	} else {
		!cp "~/.config/justfile" ($dir | path join "justfile")
	}
	cd $dir
}

# create new files/directories.
def new [suffix: string, ...rest] {
	if ($suffix == '/') {
		for $name in $rest {
			mkdir $name
			print ("Created `" + $name + "/`")
		}
	} else {
		for $name in $rest {
			touch ($name + "." + $suffix)
			print ("Created `" + $name + "." + $suffix + "`")
		}
	}
}

# clear and refresh shell
def r [] {
	clear
	exec nu
}

# ✨ setup
use $"($MY_SCRIPTS)/setup.nu" *

# ✨ clipboard
use $"($MY_SCRIPTS)/clipboard.nu" *

# ✨ chezmoi
use $"($MY_SCRIPTS)/chezmoi.nu" *

# ✨ just
use $"($MY_SCRIPTS)/just.nu" *

# ✨ System Installers
use $"($MY_SCRIPTS)/system-installer.nu" *

# ✨ Python
use $"($MY_SCRIPTS)/python.nu" *

# ✨ Rust
use $"($MY_SCRIPTS)/rust.nu" *

# ✨ JavaScript
use $"($MY_SCRIPTS)/javascript.nu" *

# ✨ Java
use $"($MY_SCRIPTS)/java.nu" *

# ✨ aichat
use $"($MY_SCRIPTS)/aichat.nu" *

# ✨ open-with
use $"($MY_SCRIPTS)/open-with.nu" *

# ✨ gh
use $"($MY_SCRIPTS)/gh-actions.nu" *
