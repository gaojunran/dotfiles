# jj 在 colocated 仓库里会把 git 的 HEAD 指到 @ 的父提交（detached HEAD）。
# 这里把 HEAD 挂回分支，让 git 工具和 agent 看到正常的当前分支。
# 两边各一个入口：
#   - 你的交互 shell（fish_prompt 钩子）
#   - agent 的 bash（BASH_ENV 钩子，逻辑在 ~/.config/shell/agent-bash-env.sh）

# ---- 交互 fish：每个提示符前检查一次 ----
function __git_attach_hook --on-event fish_prompt
    set -l branch (command git rev-parse --abbrev-ref HEAD 2>/dev/null)
    or return 0
    test "$branch" = HEAD
    or return 0
    command -v git-attach >/dev/null 2>&1
    or return 0
    command git-attach --follow --quiet
end

# ---- agent 的 bash：只在启动 agent 宿主时注入 BASH_ENV ----
# AFT 的 shell 工具固定用 /usr/bin/bash，读不了 fish 的配置，只能靠 BASH_ENV 继承。
# 不设成全局，避免影响平时跑的其它 bash 脚本。
function __git_attach_bash_env
    set -lx BASH_ENV $HOME/.config/shell/agent-bash-env.sh
    $argv
end

function openchamber --wraps openchamber
    __git_attach_bash_env command openchamber $argv
end

function opencode --wraps opencode
    __git_attach_bash_env command opencode $argv
end
