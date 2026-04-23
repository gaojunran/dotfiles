# PATH
fish_add_path -U $HOME/.cargo/bin
fish_add_path -U $HOME/.local/bin
fish_add_path -U $HOME/.moon/bin

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
