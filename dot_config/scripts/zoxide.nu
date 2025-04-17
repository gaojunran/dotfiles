# zoxide
export def --env cd [ dir?: string ] {
	if ($dir == null) {
		z
	} else {
		z $dir
	}
	if (("justfile" | path exists) and (open "justfile" | find "cd:" | length) > 0) {
		just cd
	}
}

# mkdir and cd into it.
export def --env mc [ dir: string ] {
	mkdir $dir
	if ("justfile" | path exists) {
		!cp "justfile" ($dir | path join "justfile")
	} else {
		# !cp "~/.config/justfile" ($dir | path join "justfile")
	}
	cd $dir
}

# Only code directories are needed to be cd into.
# Other dirs (Documents, Downloads, etc.) are included in yazi.nu.
export alias cdp = cd ~/Playground
export alias cdi = cd ~/Projects
export alias cdhw = cd ~/Homework
export alias cdw = cd ~/Work
