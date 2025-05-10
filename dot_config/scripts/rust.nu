export alias cg = cargo
export alias cgx = cargo uninstall

# 🎉 Create a Rust application project using cargo, and: 
# 1. cd into it.
# 2. Initialize a git repo.
# 3. Copy a rust-specific .gitignore file.
# 4. Copy a rust-specific justfile.
export def --wrapped --env cgn [ name: string, ...rest ] {
	cargo new $name ...$rest
	cd $name
	gitignore Rust
	!cp ~/.config/templates/rust.justfile justfile
}

export def --wrapped cgi [...args] {
	if ($args | length ) == 0 {
		cargo check
	} else {
		cargo add ...$args
	}
}
export alias cgb = cargo build
export alias cgt = cargo test
export alias cgii = cargo install
export alias cgxx = cargo uninstall
