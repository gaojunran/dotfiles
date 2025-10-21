use std/util "path add"

const MY_SCRIPTS = "~/.config/scripts"
const MY_BIN = "~/.config/bin"
const MY_AUTOLOAD = "~/.config/autoload"

$env.config.buffer_editor = "code"
$env.config.show_banner = false
if (is-installed "edit") {
	$env.EDITOR = "edit"
}
$env.TERM = "xterm-256color"  # for ghostty
$env.config.shell_integration.osc133 = false # for wezterm

# Use difft
if (is-installed "difft") {
	$env.GIT_EXTERNAL_DIFF = "difft --color=always --display=inline"
}

# Windows does not have $env.HOME and its default working directory
$env.HOME = '~' | path expand



# Yazi, for Windows compatibility
$env.YAZI_CONFIG_HOME = "~/.config/yazi" | path expand

# homebrew
export-env {
  $env.HOMEBREW_API_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
  $env.HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
  $env.HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
  $env.HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
	$env.HOMEBREW_CASK_OPTS = "--appdir=~/Applications"  # install in HOME instead of in root, to save disk space
}

# postgres
$env.PGDATA = "/opt/homebrew/var/postgresql@17"

# source files

# zoxide
# To initialize it, run `setup-init`.
source ($MY_AUTOLOAD | path join "zoxide.nu" | path expand)

# starship
# To initialize it, run `setup-init`.
source ($MY_AUTOLOAD | path join "starship.nu" | path expand)

# mise
# To initialize it, run `setup-init`.
use ($MY_AUTOLOAD | path join "mise.nu" | path expand)
mise mise_hook  # update immediately

# atuin
# To initialize it, run `setup-init`.
source ($MY_AUTOLOAD | path join "atuin.nu" | path expand)

# VPN proxy

if not ($env.AVOID_CLASH? == "true") {
    $env.http_proxy = "http://127.0.0.1:7897"
    $env.https_proxy = "http://127.0.0.1:7897"
}

# ----------------------------

# 🪐 Alias/Command definitions

alias q = exit
alias cat = bat
alias ts = tailscale
alias ff = fastfetch
alias of = onefetch
alias g = lazygit
alias ls = ls -a
alias tree = eza -T --hyperlink --git-ignore
# bottom, to monitor system stats, using htop style
alias top = btm -b
# https://github.com/antfu/iroiro, to pick colors
alias iro = npx iroiro
alias hex = hexyl
alias nix = orb nu
alias dock = sudo docker
alias ar = aria2c
alias ou = ouch
alias ouc = ouch compress --gitignore
alias oud = ouch decompress
alias mdx = create-mdx
alias s = zellij attach services --force-run-commands
alias pf = pitchfork
alias hf = hyperfine


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

# `rm` with a better default configuration (Auto trash, force, recursive, and able to remove PWD itself.)
def --env rm [
	...args
] {
	if ($args | length) == 0 {
	  let path = $env.PWD
		cd ..
		%rm -rf --trash $path
	} else {
		%rm -rf --trash ...$args
	}
}

# backup files in the same place
def bak [...files] {
	files | each { |f| cp -rv $f ($f + ".bak") }
}

# copy file(s) to ~/Public
def share [...files] {
	cp -rv ...$files ~/Public
}

# clear and refresh shell
def r [] {
	clear
	exec nu
}

def change [] {
	now-hash | save $"(now-hash).txt"
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
# use $"($MY_SCRIPTS)/just.nu" *

# ✨ Software Managers
use $"($MY_SCRIPTS)/software-manager.nu" *

# ✨ Package Managers
use $"($MY_SCRIPTS)/package-manager.nu" *

# ✨ aichat
use $"($MY_SCRIPTS)/aichat.nu" *

# ✨ open-with
use $"($MY_SCRIPTS)/open-with.nu" *

# ✨ gh
use $"($MY_SCRIPTS)/gh.nu" *

# ✨ bash-env, disabled as I've never used it.
# use $"($MY_SCRIPTS)/bash-env.nu" *

# ✨ git, disabled as I use hj.
# use $"($MY_SCRIPTS)/git.nu" *

# ✨ sql
use $"($MY_SCRIPTS)/sql.nu" *

# ✨ mise
use $"($MY_SCRIPTS)/mise.nu" *

# ✨ blog
use $"($MY_SCRIPTS)/blog.nu" *

# ✨ himalaya
use $"($MY_SCRIPTS)/himalaya.nu" *

# ✨ mihome
use $"($MY_SCRIPTS)/mihome.nu" *


