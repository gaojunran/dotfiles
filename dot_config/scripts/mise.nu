export alias mi = mise ls
export def miu [...args] {
  if ($args | length) == 0 {
    mise ls --installed --json
      | from json
      | transpose key value
      | each { |it| $it.value 
          | each { |entry| $"($it.key)@($entry.version)" }
        }
      | flatten
      | to text
      | fzf
      | mise use $in
  } else {
    mise use ...$args
  }
}
export def mil [...args] {
  mise ls-remote ...$args | bat
}
