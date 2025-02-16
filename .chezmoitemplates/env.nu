use std/util "path add"

path add "/opt/homebrew/bin"
path add "/nix/var/nix/profiles/default/bin"

zoxide init nushell | save -f ~/.zoxide.nu

# From https://github.com/AntKazakovv/nix-nushell-env
let nixNuScript = ("~/.config/scripts/nix.nu" | path expand)

if ($nixNuScript | path exists) {
    nu $nixNuScript | from json | load-env
}