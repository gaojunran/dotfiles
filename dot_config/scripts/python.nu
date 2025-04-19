export alias uvr = uv run
export alias uvx = uv remove

# 🎉 Create a Python application project using uv, and: 
# 1. cd into it.
# 2. Initialize a git repo.
# 3. Copy a python-specific .gitignore file.
# 4. Copy a python-specific justfile.
export def --wrapped --env uvn [ name: string, ...rest ] {
	mc $name
	print "🚀 Initializing using uv ..."
	uv init ...$rest
	mv "hello.py" "main.py"
	gitignore Python
	!cp ~/.config/templates/python.justfile justfile
}

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
export alias uvii = uv tool install
export alias uvxx = uv tool uninstall
export alias uvll = uv tool list
export alias uvuu = uv tool upgrade
export alias uvrr = uv tool run
