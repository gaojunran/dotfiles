export def mu [...args] {
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
export def ml [...args] {
  mise ls-remote ...$args | bat
}


export alias run = mise run

export def d [] {
  if (is-installed "zellij") {
    zellij --layout ~/.config/zellij/project-default.kdl
  } else {
    print "zellij is not installed!"
    mise run dev
  }
}

export alias t = mise run test
export alias b = mise run build

