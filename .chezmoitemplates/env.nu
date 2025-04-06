# 🪐 Utils

# Checks if a command is installed, return boolean.
def is-installed [ app: string ] {
	((which $app | length) > 0)
}

# Check if it's Windows now.
def is-windows [] {
    $nu.os-info.name == "windows"
}

# Check if it's macOS now.
def is-macos [] {
    $nu.os-info.name == "macos"
}

# Check if it's Linux now.
def is-linux [] {
    $nu.os-info.name == "linux"
}

use std/util "path add"

# 🪐 PATH
path add "~/.config/bin"
path add "/opt/homebrew/bin"
# path add "/nix/var/nix/profiles/default/bin"
path add "/opt/homebrew/opt/openjdk@21/bin"
path add "/opt/homebrew/bin"
path add "/opt/homebrew/anaconda3/bin"
path add "~/.cargo/bin"
path add "~/Library/Application Support/JetBrains/Toolbox/scripts"
path add "~/Projects/scripts"
path add "/usr/local/bin"
path add "~/.local/bin"
path add "/home/linuxbrew/.linuxbrew/bin"
path add "/opt/homebrew/opt/postgresql@17/bin"
path add "~/.jenv/bin"

# 🪐 Env

# VPN proxy
if (not (is-linux)) {
    $env.http_proxy = "http://127.0.0.1:7897"
    $env.https_proxy = "http://127.0.0.1:7897"
}


# Yazi, for Windows compatibility
$env.YAZI_CONFIG_HOME = "~/.config/yazi" | path expand

if (is-installed "zoxide") {
    zoxide init nushell | save -f ~/.zoxide.nu
} else {
    touch ~/.zoxide.nu
}

# From https://github.com/AntKazakovv/nix-nushell-env
# let nixNuScript = ("~/.config/scripts/nix.nu" | path expand)

# if ($nixNuScript | path exists) {
#     nu $nixNuScript | from json | load-env
# }
