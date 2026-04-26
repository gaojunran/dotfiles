set fish_greeting

function fish_prompt
    set_color blue
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
alias c "code ."  # FIXME: maybe later a dynamic env
alias o "start"
alias cd z    # FIXME: can be better
alias cdp "builtin cd ~/Playground"
alias cdi "builtin cd ~/Projects"
alias cdw "builtin cd ~/Work"
alias bri "brew install"
alias bru "brew upgrade"
alias brl "brew list"
alias brx "brew uninstall"
alias brs "brew search"

alias cm "hj commit"
alias pp "hj push"
alias pl "hj pull"
alias desc "hj desc -m"
alias sh "hj show"  # FIXME: this overrides the default sh
alias ss "hj show --stat"
alias df "hj diff"  # FIXME: this overrides the default df


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
