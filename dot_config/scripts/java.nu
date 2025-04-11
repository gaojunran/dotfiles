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
# Create a Gradle project and cd into it.
export def --wrapped --env gdn [ name: string, ...rest ] {
  mc $name
	gd init ...$rest
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
