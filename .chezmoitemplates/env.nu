use std/util "path add"

# 🪐 PATH

path add "/opt/homebrew/bin"
path add "/nix/var/nix/profiles/default/bin"
path add "/opt/homebrew/opt/openjdk@21/bin"
path add "/opt/homebrew/bin"
path add "/opt/homebrew/anaconda3/bin"
path add "~/.cargo/bin"
path add "~/Library/Application Support/JetBrains/Toolbox/scripts"
path add "~/Projects/scripts"
path add "/usr/local/bin"

# 🪐 Env

$env.config.buffer_editor = "code"
$env.config.show_banner = false

# VPN proxy
$env.http_proxy = "http://127.0.0.1:7897"
$env.https_proxy = "http://127.0.0.1:7897"

# Yazi, for Windows compatibility
$env.YAZI_CONFIG_HOME = "~/.config/yazi"

zoxide init nushell | save -f ~/.zoxide.nu

# From https://github.com/AntKazakovv/nix-nushell-env
let nixNuScript = ("~/.config/scripts/nix.nu" | path expand)

if ($nixNuScript | path exists) {
    nu $nixNuScript | from json | load-env
}