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
export def --env mc [ 
	dir?: string # if is not given, use current time as dirname
] {
	let dir = $dir | default (date now | format date "demo-%Y-%m-%d-%H-%M-%S")
	mkdir $dir
	cd $dir
}



# Only code directories are needed to be cd into.
# Other dirs (Documents, Downloads, etc.) are included in yazi.nu.
export alias cdp = cd ~/Playground
export alias cdi = cd ~/Projects
export alias cdhw = cd ~/Homework
export alias cdw = cd ~/Work
