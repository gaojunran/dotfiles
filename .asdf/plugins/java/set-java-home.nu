let $java_path = (asdf which java)

if $java_path != "" {
    let $full_path = (realpath $java_path | lines | first | str trim)
    let $java_home = ($full_path | path dirname | path dirname)
    $env.JAVA_HOME = $java_home
    $env.JDK_HOME = $java_home
}

