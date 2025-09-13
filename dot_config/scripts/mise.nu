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
      | fzf -m
      | split row "\n" 
      | each { |tool| mise use $tool --path ./mise.toml }
      | to text
  } else {
    mise use ...$args --path .
  }
}
export def mil [...args] {
  mise ls-remote ...$args | bat
}
export alias mii = mise install
