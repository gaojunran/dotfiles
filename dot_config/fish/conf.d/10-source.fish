# 固定的 env vars
# 注意：动态变化的环境变量应由 mise or fnox 管理
# 据说在 config.fish 里用 -Ux 才是标准做法
set -Ux HOMEBREW_CASK_OPTS "--appdir=$HOME/Applications"
set -Ux TERM "xterm-256color" # ghostty
set -Ux PNPM_HOME "/Users/nebula/Library/pnpm"


# PATH
fish_add_path -U $HOME/.cargo/bin
fish_add_path -U $HOME/.local/bin
fish_add_path -U $HOME/.moon/bin
fish_add_path -U $PNPM_HOME

# brew
/opt/homebrew/bin/brew shellenv fish | source

# zoxide
zoxide init fish | source

# pitchfork
# FIXME: use brew to install pitchfork; now using cargo
pitchfork activate fish | source

# fnox
fnox activate fish | source

# 注意：后面与具体项目相关的开发工具优先用 mise 来安装。
