const MY_TEMPLATES = "~/.config/templates"
const MY_AUTOLOAD = "~/.config/autoload"

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

# Clone a language-specific gitignore file.
def gitignore [ category: string ] {
	curl -o .gitignore ('https://raw.githubusercontent.com/github/gitignore/refs/heads/main/' + $category + '.gitignore')
    open ($"($MY_TEMPLATES)/general.gitignore" | path expand) | save --append .gitignore
}

use std/util "path add"

# 🪐 PATH
path add "~/.config/bin"
path add "/opt/homebrew/bin"
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
path add "~/.asdf/shims"

# 🪐 Env

# Create empty script to avoid errors when `source`.
mkdir ~/.asdf/plugins/java
touch ~/.asdf/plugins/java/set-java-home.nu

# Redirect default commands
alias "!cd" = cd
alias "!cp" = cp
alias "!cat" = cat
alias "!ps" = ps
