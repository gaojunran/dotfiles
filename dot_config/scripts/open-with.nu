# yazi
export def --env y [...args] {
	let tmp = (mktemp -t "yazi-cwd.XXXXXX")
	yazi ...$args --cwd-file $tmp
	let cwd = (open $tmp)
	if $cwd != "" and $cwd != $env.PWD {
		cd $cwd
	}
	rm -fp $tmp
}
# Open in HOME and do not change cwd when quitting. Often used for searching files.
export alias yy = yazi ~
export alias hw = y ~/Homework
export alias yd = y ~/Downloads
export alias yD = y ~/Documents
export alias ys = y ~/Pictures/Screenshots
export alias yp = y ~/Playground
export alias yP = y ~/Projects


# use code to open in pwd, or open a dir.
export def c [ arg?: string ] {
  if $in == null and $arg == null {
		code .
	} else if $arg == null {
		code $in
	} else {
		code $arg
	}
	if (is-installed "zellij") {
		zellij --layout ~/.config/zellij/project-default.kdl
	}
	
}

# use idea to open in pwd, or open a dir.
export def i [ arg?: string ] {
  if $in == null and $arg == null {
		idea .
	} else if $arg == null {
		idea $in
	} else {
		idea $arg
	}
}

# use finder to open in pwd, or open a dir.
export def o [ arg?: string ] {
	if $in == null and $arg == null {
		start .
	} else if $arg == null {
		start $in
	} else {
		start $arg
	}
}
