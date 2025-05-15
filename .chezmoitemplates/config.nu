use std/util "path add"

const MY_SCRIPTS = "~/.config/scripts"
const MY_BIN = "~/.config/bin"
const MY_AUTOLOAD = "~/.config/autoload"

$env.config.buffer_editor = "code"
$env.config.show_banner = false
$env.EDITOR = "code"

# Windows does not have $env.HOME and its default working directory
$env.HOME = '~' | path expand

# VPN proxy
if (not (is-linux)) {
    $env.http_proxy = "http://127.0.0.1:7897"
    $env.https_proxy = "http://127.0.0.1:7897"
}

# Yazi, for Windows compatibility
$env.YAZI_CONFIG_HOME = "~/.config/yazi" | path expand

# Set encoding to UTF-8
if (is-windows) {
    chcp 65001 | ignore
}

# make binaries executable in unix
if not (is-windows) {
	ls ($MY_BIN | path expand) | each { |f| chmod +x ($MY_BIN | path join $f.name) }
}

# source files

# zoxide
# To initialize it, run `setup-once`.
source ($MY_AUTOLOAD | path join "zoxide.nu" | path expand)

# starship
# To initialize it, run `setup-once`.
source ($MY_AUTOLOAD | path join "starship.nu" | path expand)

# mise
# To initialize it, run `setup-once`.
use ($MY_AUTOLOAD | path join "mise.nu" | path expand)


# ----------------------------

# 🪐 Alias/Command definitions

alias q = exit
alias cat = bat
alias ts = tailscale
alias ff = fastfetch
alias of = onefetch
alias g = lazygit
alias ls = ls -a
alias rm = rm -rf --trash
alias tree = eza -T --hyperlink
# bottom, to monitor system stats, using htop style
alias top = btm -b
# https://github.com/antfu/iroiro, to pick colors
alias iro = npx iroiro
alias hex = hexyl
alias nix = orb nu
alias dock = sudo docker

# Find help from `<command> --help`.
def "?" --wrapped [
	...cmd
] {
	nu -l -c (($cmd | str join " ") +  " --help")
}



# create new files/directories.
def new [suffix: string, ...rest: string] {
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

# ✨ zoxide
use $"($MY_SCRIPTS)/zoxide.nu" *

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
use $"($MY_SCRIPTS)/gh.nu" *

# ✨ xmake
use $"($MY_SCRIPTS)/xmake.nu" *

# ✨ bash-env
use $"($MY_SCRIPTS)/bash-env.nu" *

# ✨ git
use $"($MY_SCRIPTS)/git.nu" *

# ✨ sql
use $"($MY_SCRIPTS)/sql.nu" *

# ✨ repomix 
use $"($MY_SCRIPTS)/repomix.nu" *

# ✨ mise
use $"($MY_SCRIPTS)/mise.nu" *

# ✨ mirrors
use $"($MY_SCRIPTS)/mirrors.nu" *

# ✨ pandoc
use $"($MY_SCRIPTS)/pandoc.nu" *
