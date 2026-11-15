# 由 BASH_ENV 注入到 agent 的每个非交互 bash 启动时（AFT 的 shell 工具固定走 /usr/bin/bash）。
# 三件事（大致按执行顺序）：
#   1. fnox 的 fallback：插件 agent-shell-env.ts 没加载时（无 AGENT_SHELL_ENV 标记）
#      才在这里自己跑一次 fnox hook-env
#   2. 当前目录属于某个 mise 项目时，按目录加载工具版本和 [env]（模板可能读上面的 secrets）
#   3. 把 jj 留在 colocated 仓库里的 detached HEAD 挂回分支
#
# 约定：零输出、不改变调用方退出码（结尾必须 return 0），
# 否则在 `set -e` 的脚本里钩子返回非零会让那个脚本直接退出。

_agent_bash_hook() {
    [[ -n ${_AGENT_BASH_HOOK:-} ]] && return 0

    local d has_mise="" has_fnox=""
    d=$PWD
    while :; do
        [[ -f $d/mise.toml || -f $d/.mise.toml ]] && has_mise=1
        [[ -f $d/fnox.toml || -f $d/.fnox.toml ]] && has_fnox=1
        [[ -n $has_mise && -n $has_fnox ]] && break
        [[ $d == / ]] && break
        d=${d%/*}
        [[ -z $d ]] && d=/
    done

    # fnox 优先由 ~/.config/opencode/plugins/agent-shell-env.ts 注入（按命令实际目录、进程内缓存）。
    # 它不在时（插件没加载）才在这里回退，保证 secrets 不会凭空消失。
    if [[ -n $has_fnox && -z ${AGENT_SHELL_ENV:-} ]] && command -v fnox >/dev/null 2>&1; then
        eval "$(command fnox hook-env -s bash --if-missing ignore 2>/dev/null)" || true
    fi
    if [[ -n $has_mise ]] && command -v mise >/dev/null 2>&1; then
        # -q 只压掉 warning，保留 error（例如 config 未被 trust，此时 mise 完全不生效）
        eval "$(command mise hook-env -s bash -q)" || true
    fi

    # jj 把 HEAD 指到 @ 的父提交，这里挂回分支（--follow 只在 .jj 仓库里前进主分支）
    local branch
    branch=$(command git rev-parse --abbrev-ref HEAD 2>/dev/null) || return 0
    [[ $branch == HEAD ]] || return 0
    command -v git-attach >/dev/null 2>&1 || return 0
    _AGENT_BASH_HOOK=1 command git-attach --follow --quiet >/dev/null 2>&1
    return 0
}

_agent_bash_hook || true
unset -f _agent_bash_hook
return 0
