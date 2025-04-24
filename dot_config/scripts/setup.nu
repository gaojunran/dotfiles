# 📢 Install all dependences. See https://github.com/gaojunran/dotfiles?tab=readme-ov-file#dependences-setup.
export def "setup-deps" [] {
	if (is-windows) {
		scoop import ~/.config/setup/scoop-deps.json
	} else if (is-macos) {
		brew bundle --file ~/.config/setup/brew-deps
	} else {
		"Use your own package manager bro! TODO: yay's automation"
	}
	asdf plugin 
}

# 📢 Install all applications. See https://github.com/gaojunran/dotfiles?tab=readme-ov-file#applications-setup.
export def "setup-apps" [] {
	if (is-windows) {
		scoop import ~/.config/setup/scoop-apps.json
	} else if (is-macos) {
		brew bundle --file ~/.config/setup/brew-apps
	} else {
		"Do you want to use GUI apps in Linux? Anyway, I don't."
	}
}

export def "setup-once" [] {
	const MY_AUTOLOAD = "~/.config/autoload"
	if (is-installed "zoxide") {
		zoxide init nushell | str replace -a "cd" "!cd" | save -f ($MY_AUTOLOAD | path join "zoxide.nu")
	} else {
		print "⚠️ `zoxide` is not installed. Skip."
	}
	if (is-installed "starship") {
		starship init nu | save -f ($MY_AUTOLOAD | path join "starship.nu")
	} else {
		print "⚠️ `starship` is not installed. Skip."
	}
	# I do not use `activate` in `mise`.
	if (is-installed "mise") {
		^mise activate nu 	| str replace -r '\$env\.Path = \(\$env\.Path \| prepend.*\)' "" 
											| save -f ($MY_AUTOLOAD | path join "mise.nu")
	} else {
		print "⚠️ `mise` is not installed. Skip."
	}
}
