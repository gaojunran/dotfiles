# 固定的 env vars
# 注意：动态变化的环境变量应由 mise or fnox 管理
# 据说在 config.fish 里用 -Ux 才是标准做法
set -Ux HOMEBREW_CASK_OPTS "--appdir=$HOME/Applications"
set -Ux TERM "xterm-256color" # ghostty
set -Ux PNPM_HOME $HOME/Library/pnpm
set -Ux EDITOR hx
set -Ux PRIVCONF_DIR $HOME/.local/share/chezmoi/dot_config/privconf


# PATH 注意因为是 prepend，在后面的反而优先级更高。
# 对已存在于 PATH 的目录，需要加 -m 才会被挪到更前面。
fish_add_path -U /opt/homebrew/bin
fish_add_path -U $HOME/.cargo/bin
fish_add_path -U $HOME/.moon/bin
fish_add_path -U $PNPM_HOME
fish_add_path -U $PNPM_HOME/bin
fish_add_path -U -m $HOME/.local/bin
fish_add_path -U -m $HOME/.local/bin/scripts

# linuxbrew
if test -x /home/linuxbrew/.linuxbrew/bin/brew
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv fish)"
end

# mise
# 为了避免可能存在的激活时序问题，直接在这里手动激活
set -gx MISE_FISH_AUTO_ACTIVATE 0
mise activate fish | source

# zoxide
if type -q zoxide
  zoxide init fish | source
end

# pitchfork
if type -q pitchfork
  pitchfork activate fish | source
end

# fnox
if type -q fnox
  fnox activate fish | source
end

# 注意：后面与具体项目相关的开发工具优先用 mise 来安装。
