# 固定的 env vars
# 注意：动态变化的环境变量应由 mise or fnox 管理
# 据说在 config.fish 里用 -Ux 才是标准做法
set -Ux HOMEBREW_CASK_OPTS "--appdir=$HOME/Applications"
set -Ux TERM "xterm-256color" # ghostty
set -Ux PNPM_HOME $HOME/Library/pnpm
set -Ux EDITOR hx


# PATH
fish_add_path -U $HOME/.cargo/bin
fish_add_path -U $HOME/.local/bin
fish_add_path -U $HOME/.moon/bin
fish_add_path -U $PNPM_HOME

# brew
if not type -q brew
  # 注意：brew + fish 不需要 activate，但其他情况需要
  mise activate fish | source
end

# zoxide
if type -q zoxide
  zoxide init fish | source
end

# pitchfork
# FIXME: use brew to install pitchfork; now using cargo
if type -q pitchfork
  pitchfork activate fish | source
end

# fnox
if type -q fnox
  fnox activate fish | source
end

# 注意：后面与具体项目相关的开发工具优先用 mise 来安装。
