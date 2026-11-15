# 由 BASH_ENV 在每个非交互 bash 启动时被 source（agent 的 shell 工具固定走 /usr/bin/bash）。
# jj 在 colocated 仓库里会把 git 的 HEAD 指到 @ 的父提交（detached HEAD），
# 这里在命令真正执行前把 HEAD 挂回分支，让 agent 看到正常的当前分支。
#
# 约定：零输出、不改调用方的退出码（结尾必须 return 0）。
# 否则在 `set -e` 的脚本里，钩子返回非零会让那个脚本直接退出。

_git_attach_bash_hook() {
    [[ -n ${_GIT_ATTACH_HOOK:-} ]] && return 0
    local branch
    branch=$(command git rev-parse --abbrev-ref HEAD 2>/dev/null) || return 0
    [[ $branch == HEAD ]] || return 0
    command -v git-attach >/dev/null 2>&1 || return 0
    _GIT_ATTACH_HOOK=1 command git-attach --follow --quiet >/dev/null 2>&1
    return 0
}

_git_attach_bash_hook || true
unset -f _git_attach_bash_hook
return 0
