const DB_CONNECTIONS_FILE = "~/.db_connections" | path expand

# Open a database connection, powered by usql and fzf.
# Db connections info are stored in `~/.db_connections`.
export def main [
	name_or_connection?: string # Either specify a name defined in ~/.db_connections, or a connection string for usql.
] {
	def get-all-connections [] {
		return (
							open $DB_CONNECTIONS_FILE 
							| lines
							| str trim
							| split column "\t" 
							| rename name connection
					)
	}

	def get-connection [name: string] {
	  return (
							get-all-connections 
							| where $it.name == $name
							| if ($in | length) > 0 { first | get connection } 
								else { null }
					)
	}
	def get-name [connection: string] {
	  return (
							get-all-connections 
							| where $it.connection == $connection
							| if ($in | length) > 0 { first | get name } 
								else { null }
					)
	}
	def combine [leading: string, trailing: string] {
		if ($leading | str substring (($leading | str length) - 1)..($leading | str length)) == "/" {
			return ($leading + $trailing)
		} else {
			return ($leading + "/" + $trailing)
		}
	}
	if ($name_or_connection == null) {
		# nothing is given, show all connections
		let connection = get-all-connections 
				| each { |it| $"($it.name): ($it.connection)" } 
				| to text 
				| fzf 
				| split column ": " 
				| get column2
				| to text 
				| str trim
		usql $connection
	} else if ($name_or_connection | str contains "://") {
		# given a connection string
		let connection = $name_or_connection
		let name  = (get-name $connection)
		if $name == null {
		  ((input "📢 A new connection will be created. Give it an alias (`_` to skip): ") 
				+ "\t" + $connection + "\n" )
				| save --append $DB_CONNECTIONS_FILE
		} else {
			print $"📢 The connection already exists. Type the alias `($name)` next time!"
		}
		usql $connection
	} else if ($name_or_connection | str contains "::") {
		# given a shorthand connection string
		let leading = $name_or_connection | split column "::" 
															| get column1 | to text | str trim 
		let trailing = $name_or_connection | split column "::" 
															| get column2 | to text | str trim
		let leading_connection = (get-connection $leading)
		if $leading_connection == null {
		  print $"❌ The connection name `($leading)` does not exist!"
		} else {
			let connection = combine $leading_connection $trailing
			let name = (get-name $connection)
			if $name == null {
			  ((input "📢 A new connection will be created. Give it an alias (`_` to skip): ") 
					+ "\t" + $connection + "\n" )
					| save --append $DB_CONNECTIONS_FILE
			} else {
				print $"📢 The connection already exists. Type the alias `($name)` next time!"
			}
			usql $connection
		}
	} else {
		# given a name
		let name = $name_or_connection
		let connection = (get-connection $name)
		if $connection == null {
			print $"❌ The connection name `($name)` does not exist!"
		} else {
			usql $connection
		}
	}
}

export alias pg = main pg
export alias my = main my
