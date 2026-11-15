# jj 在 colocated 仓库里会把 git 的 HEAD 指到 @ 的父提交（detached HEAD）。
# 这里在每个提示符前顺手把它挂回分支，让 git 工具和 agent 看到正常的当前分支。
# 只在确实 detached 时才 fork；机器上没装 git-attach 就跳过。

function __git_attach_hook --on-event fish_prompt
    set -l branch (command git rev-parse --abbrev-ref HEAD 2>/dev/null)
    or return 0
    test "$branch" = HEAD
    or return 0
    command -v git-attach >/dev/null 2>&1
    or return 0
    command git-attach --follow --quiet
end
