# zoxide
export def --env cd [ dir?: string ] {
	if ($dir == null) {
		z
	} else {
		z $dir
	}
	# support mise and asdf, only use mise.
	if ("mise.toml" | path exists) or (".tool_versions" | path exists) {
		mise trust | complete | ignore  # trust config files
		mise install # auto install dependencies
	}
	# if (".jj" | path exists) {
	# 	hj pull main
	# }
}

# mkdir and cd into it.
export def --env mc [ 
	dir?: string # if is not given, use a hash as dirname
] {
	# If you want to create a dir in HOME, just `mkdir` and `cd`. 
	# By default, `mc` in HOME is not allowed.
	if $dir == null or $env.PWD == $env.HOME {
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
