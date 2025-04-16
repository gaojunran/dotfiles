# usql actions
export def pg [db?: string] {
	if $db == null {
		usql "pg://postgres@localhost:5432/"
	} else {
		usql ("pg://postgres@localhost:5432/" + $db)
	}
}
