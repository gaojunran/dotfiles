export alias dot = chezmoi
export alias dota = dot apply --force
export alias dote = code (dot source-path)
export def dotu [] {
  dot update --apply
  setup-once
  r
}
export def dotr [] {
  dota
  setup-once
  r
}
