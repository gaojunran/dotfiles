# zoxide
export def --env cd [ dir?: string ] {
	if ($dir == null) {
		z
	} else {
		z $dir
	}
	if ("mise.toml" | path exists) {
		mise trust  # trust config files
		mise install # auto install dependencies
	}
}

# mkdir and cd into it.
export def --env mc [ 
	dir?: string # if is not given, use a hash as dirname
] {
	if $dir == null {
		cd ~/Playground
	}
	let dir = $dir | default ("proj_" + (now-hash))
	mkdir $dir
	cd $dir
}

# Only code directories are needed to be cd into.
# Other dirs (Documents, Downloads, etc.) are included in yazi.nu.
export alias cdp = cd ~/Playground
export alias cdi = cd ~/Projects
export alias cdw = cd ~/Work
