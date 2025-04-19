export alias dot = chezmoi
export alias dota = dot apply --force
export alias dote = code (dot source-path)
export alias dotu = dot update --apply
export def dotr [] {
  dota
  setup-once
  r
}
