# ✨ Python (uv)

export alias uvr = uv run
export alias uvx = uv remove

# 🎉 Create a Python application project using uv, and:
# 1. cd into it.
# 2. Initialize a git repo.
# 3. Clone a python-specific .gitignore file.
# 4. Copy a python-specific justfile.
# export def --wrapped --env uvn [ name: string, ...rest ] {
# 	mc $name
# 	uv init ...$rest | complete | prompt "Initializing using uv ..."
# 	# mv "hello.py" "main.py"  # Disabled because uv has a default main.py now.
# 	internal "gitignore Python" | complete | prompt "Downloading .gitignore ..."
# 	internal "%cp ~/.config/templates/python.justfile justfile" | complete | prompt "Copying justfile ..."
# }

# Sync the env with pyproject.toml, requirements.txt, or simply add a package.
export def --wrapped uvi [...args] {
	if ($args | length ) == 0 {
		uv sync
		if ("requirements.txt" | path exists) {
			uv pip sync requirements.txt
		}
	} else {
		uv add ...$args
	}
}


# ✨ Rust (cargo)

export alias cg = cargo
export alias cgx = cargo uninstall

# 🎉 Create a Rust application project using cargo, and:
# 1. cd into it.
# 2. Initialize a git repo.
# 3. Clone a rust-specific .gitignore file.
# 4. Copy a rust-specific justfile.
export def --wrapped --env cgn [ name: string, ...rest ] {
	cargo new $name ...$rest | complete | prompt "Initializing using cargo ..."
	cd $name
	internal "gitignore Rust" | complete | prompt "Downloading .gitignore ..."
	internal "%cp ~/.config/templates/rust.justfile justfile" | complete | prompt "Copying justfile ..."
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
export alias cgr = cargo run

# ✨ gradle
# Use wrapper if exists, otherwise use gradle directly (often to init a new project).
export def --wrapped gd [...args] {
	if (is-windows) and ("./gradlew.bat" | path exists) {
		.\gradlew.bat ...$args
	} else if ("./gradlew" | path exists) {
		./gradlew ...$args
	} else {
		gradle ...$args
	}
}
export alias gdb = gd build
export alias gdr = gd run
export alias gdt = gd test
export alias gdf = gd format

# ✨ maven
export def mvr [] {
	mvn clean package
	let jar = ls ./target | where name =~ "jar" | first | get name
	java -jar $jar
}
export alias mvc = mvn clean

# ✨ pnpm
# Sync the env with package.json, or simply add a package.
export alias pni = pnpm install
export alias pnr = pnpm run
export alias pnx = pnpm remove

# ✨ bun
# Sync the env with package.json, or simply add a package.
export alias bui = bun install
export alias bur = bun run
export alias bux = bun remove


# ✨ deno
export alias dei = deno install --npm
export alias der = deno run -A
export alias dex = deno uninstall

# ✨ xmake

# export alias xm = xmake
# export alias xmb = xmake build
# export def xmr [] {
#     xmake build
#     xmake run
# }
# export alias xmc = xmake clean
