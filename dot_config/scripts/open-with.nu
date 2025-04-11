# yazi
def --env y [...args] {
	let tmp = (mktemp -t "yazi-cwd.XXXXXX")
	yazi ...$args --cwd-file $tmp
	let cwd = (open $tmp)
	if $cwd != "" and $cwd != $env.PWD {
		cd $cwd
	}
	rm -fp $tmp
}
# Open in HOME and do not change cwd when quitting. Often used for searching files.
alias yy = yazi ~
alias hw = y ~/Homework
alias yd = y ~/Downloads
alias yD = y ~/Documents
alias ys = y ~/Pictures/Screenshots
alias yp = y ~/Playground
alias yP = y ~/Projects


# use code to open in pwd, or open a dir.
def c [ arg?: string ] {
  if $in == null and $arg == null {
		code .
	} else if $arg == null {
		code $in
	} else {
		code $arg
	}
}

# use idea to open in pwd, or open a dir.
def i [ arg?: string ] {
  if $in == null and $arg == null {
		idea .
	} else if $arg == null {
		idea $in
	} else {
		idea $arg
	}
}

# use finder to open in pwd, or open a dir.
def o [ arg?: string ] {
	if $in == null and $arg == null {
		start .
	} else if $arg == null {
		start $in
	} else {
		start $arg
	}
}
