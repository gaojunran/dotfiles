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

# starship
# 现在工具版本由 mise 管理，没有那么需要 starship
# 观察一下是否需要分支信息
# starship init fish | source


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
alias cat bat
alias ff fastfetch
alias of onefetch
alias ls "eza -a"
alias dotr "chezmoi apply -k --force && clear && exec fish"  # FIXME: remove -k --force
alias hex hexyl
alias ouc "ouch compress --gitignore"
alias oud "ouch decompress"
alias s "zellij attach services --force-run-commands"  # FIXME: find a better way to multi process
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
alias bri "brew install"
alias bru "brew upgrade"
alias brl "brew list"
alias brx "brew uninstall"
alias brs "brew search"

alias aa "aube add"
alias aag "aube add -g"

alias j "jj"
alias jn "jj new"
alias ed "jj edit"
# FIXME: replace with simple function with jj
alias am "hj amend"
alias rs "hj reset"
alias th "hj throw"
alias cm "jj commit -im"
alias ab "jj abandon"
alias jd "jj desc -m"
alias js "jj show"
alias ss "jj show --stat"
alias df "jj diff"  # FIXME: this overrides the default df
alias f "jj git fetch"
alias lr "jj log -r"
alias rb "jj rebase"
alias bt "jj b t"
alias bs "jj b s"
alias bd "jj b d"
alias ba "jj b a"
alias jun "jj undo"
alias jre "jj redo"

alias d "mise run dev"

alias 0='builtin cd ../(string replace -r "_[0-9]+\$" "" (basename $PWD))'
alias 1='builtin cd ../(string replace -r "_[0-9]+\$" "" (basename $PWD))_1'
alias 2='builtin cd ../(string replace -r "_[0-9]+\$" "" (basename $PWD))_2'
alias 3='builtin cd ../(string replace -r "_[0-9]+\$" "" (basename $PWD))_3'
alias 4='builtin cd ../(string replace -r "_[0-9]+\$" "" (basename $PWD))_4'
alias 5='builtin cd ../(string replace -r "_[0-9]+\$" "" (basename $PWD))_5'

alias cbc "codebuddy --continue --dangerously-skip-permissions"
alias cci "claude-internal --continue --dangerously-skip-permissions"
alias oc "opencode --continue"

# FIXME: 应该支持默认值为最近的书签
function dfr
    jj interdiff -f "$argv[1]@origin" -t "$argv[1]@git"
end

function cmp
    cm $argv[1] && pp
end

function pp
    set -l rev 'heads(::@ & mutable() & ~description(exact:"") & (~empty() | merges()))'
    # 未传参
    if test (count $argv) -eq 0
        jj bookmark move \
            --from 'heads(::@ & bookmarks())' \
            --to "$rev" &&
        jj git push
        return
    end

    # 传参了
    jj bookmark set -r "$rev" $argv
    or return

    set -l push_args
    for b in $argv
        set push_args $push_args -b $b
    end

    jj git push $push_args
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
