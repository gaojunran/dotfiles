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

def now-string [] {
    date now | format date "%Y-%m-%d-%H-%M-%S"
}

def now-hash [] {
    now-string | hash md5 | str substring 0..5
}

# Use after `complete` to show hints of a command and error messages if failed.
# Note that if the command runs successfully, it will not show the output.
def prompt [
    prompt: string = ""
] {
    if prompt != "" {
        print $"🚀 (ansi blue_bold)($prompt)(ansi reset)"
    }
    $in | if $in.exit_code != 0 {
        print $"❌ (ansi red)($in.stderr)(ansi reset)"
    }
}

def --env away-from-home [] {
    if $env.PWD == $env.HOME {
        cd ~/Playground
    }
}

def internal [
    command: string
] {
    nu -l -c $command
}

def success [
    message: string
] {
    print $"✅ (ansi green)($message)(ansi reset)"
}

# currently support uv/python, later will support bun/deno/js/ts.
def install-script [
    script: string
] {
    const MY_BIN = "~/.config/bin" | path expand
    mut content = open $script
    if not ($content | str starts-with "#!") {
        $content = "#!/usr/bin/env -S uv run --script\n\n" + $content
    }
    let dest = ($MY_BIN | path join ($script | path basename | str replace ".py" ""))
    cp $script $dest
    chmod +x $dest
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
path add "/opt/homebrew/opt/rustup/bin"
path add "~/.pnpm"
path add "~/.dotnet/tools"
# path add "AppData/Local/mise/shims"

# 🪐 Env

touch ~/.db_connections  # not using chezmoi to avoid to file to be overwritten

# Redirect default commands
alias "%cd" = cd
alias "%cp" = cp
alias "%cat" = cat
alias "%ps" = ps
alias "%rm" = rm

# pnpm
$env.PNPM_HOME = "~/.pnpm" | path expand
