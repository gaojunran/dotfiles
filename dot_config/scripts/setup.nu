# 📢 Install all dependences. See https://github.com/gaojunran/dotfiles?tab=readme-ov-file#dependences-setup.
export def "setup-deps" [] {
	if (is-windows) {
		scoop import ~/.config/setup/scoop-deps.json
	} else if (is-macos) {
		brew bundle --file ~/.config/setup/brew-deps
	} else {
		"Use your own package manager bro! TODO: yay's automation"
	}
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

# 📢 Run once when coming to a new machine. Prepare all the directories.
export def "setup-dirs" [] {
	mkdir -v ~/Downloads
	mkdir -v ~/Documents
	mkdir -v ~/Pictures/Screenshots
	mkdir -v ~/Videos
	mkdir -v ~/Music
  # For temporary projects.
	mkdir -v ~/Playground   
	# My projects.
	mkdir -v ~/Projects
}
