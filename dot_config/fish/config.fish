set fish_greeting

function fish_prompt
    switch (uname)
        case Darwin
            set_color blue
        case Linux
            set_color yellow
        case '*'
            set_color blue
    end
    echo -n (prompt_pwd)
    set_color normal
    echo -n ' > '
end

# yazi
function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	command yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end


# 别名
alias r "clear && exec fish"
alias ff fastfetch
alias of onefetch
alias ls "eza -a"
alias dotr "chezmoi apply -k && clear && exec fish"  # FIXME: 后面看看有没有自动合并配置的方法
alias hex hexyl
alias pc privconf
alias ouc "ouch compress --gitignore"
alias oud "ouch decompress"
alias top "btm -b"
alias pf pitchfork
alias hf hyperfine
alias cc "cb copy"
alias cv "cb paste"
alias cx "cb cut"
alias run "mise run"
alias use "mise use"
alias o "start"
alias cd z
alias c "zed ."
alias cdp "builtin cd ~/Playground"
alias cdi "builtin cd ~/Projects"
alias cdw "builtin cd ~/Work"
alias cdc "builtin cd ~/.local/share/chezmoi"

# work projects
alias cdlib "builtin cd ~/Work/wxapplib"
alias cdnp "builtin cd ~/Work/weapp-novel-plugin"
alias cdnm "builtin cd ~/Work/miniprogram-novel"
alias cdsp "builtin cd ~/Work/weapp-skit-player-plugin"
alias cdsm "builtin cd ~/Work/miniprogram-skit"

alias bri "brew install"
alias bru "brew upgrade"
alias brl "brew list"
alias brx "brew uninstall"
alias brs "brew search"

# wechatwebdevtools cli
# must use absolute path instead of `.`
alias we "/Applications/wechatwebdevtools.app/Contents/MacOS/cli open --project $(pwd)"
alias wep "/Applications/wechatwebdevtools.app/Contents/MacOS/cli preview --project $(pwd)"

# SSH remote
alias s1 "ssh jr"
alias s2 "ssh wxapplib"

alias ai "aube install --dangerously-allow-all-builds"
alias aa "aube add --dangerously-allow-all-builds"
alias aag "aube add -g --dangerously-allow-all-builds"

alias j "jj"
alias jn "jj new"
alias jnp "jj new @-"
alias ed "jj edit"
alias edp "jj edit @-"
alias pb "jj push -b"


function jnb
    jj new (eval $BASE_BRANCH_COMMAND)
end

function am
    set -q argv[1]; or set argv @-
    jj squash -i --from @ --into $argv
end

function rs
    set -q argv[1]; or set argv @-
    jj squash -i --from $argv --into @
end

function th
    set -q argv[1]; or set argv @
    jj restore -i --changes-in $argv
end

function jt
    set -q argv[1]; or set argv @
    jj new "tip($argv)"
end

alias sq "jj squash"
alias sp "jj split"

alias cm "jj commit -im"
alias ab "jj abandon"
alias jd "jj desc -m"
alias jdp "jj desc -r @- -m"
alias js "jj show"
alias jsp "jj show @-"
alias ss "jj show --stat"
alias ssp "jj show --stat @-"
alias df "jj diff"
alias f "jj git fetch"
alias lr "jj log -r"
alias rb "jj rebase"
alias bs "jj b s"
alias bd "jj b d"
alias bl "jj b l --sort committer-date-"
alias jun "jj undo"
alias jre "jj redo"

# jj log
alias lrm "lr 'mine() & ~description(\"\")' --no-graph"
alias lrme "lr 'mine() & description(\"\")' --no-graph --summary"

alias d "mise run dev"

alias 0='builtin cd ../(string replace -r "_[0-9]+\$" "" (basename $PWD))'
alias 1='builtin cd ../(string replace -r "_[0-9]+\$" "" (basename $PWD))_1'
alias 2='builtin cd ../(string replace -r "_[0-9]+\$" "" (basename $PWD))_2'
alias 3='builtin cd ../(string replace -r "_[0-9]+\$" "" (basename $PWD))_3'
alias 4='builtin cd ../(string replace -r "_[0-9]+\$" "" (basename $PWD))_4'
alias 5='builtin cd ../(string replace -r "_[0-9]+\$" "" (basename $PWD))_5'

alias oc opencode
alias occ "opencode --continue"

function cmp
    cm $argv[1..] && pp
end

function amp
    am $argv[1] && pp
end

function rbr
    rb -r $argv[1] -o $argv[2] $argv[3..]
    jn $argv[1]
end

# 获取 PR 形式的 diff，类似 Git 的三点比较
function dfpr
  set target trunk
  if test (count $argv) -gt 0
    set target $argv[1]
  end
  df --from "fork_point(@|$target)"
end

# 如果没有提供参数，则创建一个随机目录
function mc
  if test (count $argv) -gt 0
    mkdir -p $argv[1]
    cd $argv[1]
  else
    set base ~/Playground

    set name ""
    for i in (seq 6)
      set r (random 0 15)
      set h (printf "%x" $r)
      set name $name$h
    end

    set path $base/$name
    mkdir -p $path
    cd $path
  end
end
