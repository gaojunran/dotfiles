export alias dot = chezmoi
export alias dota = dot apply --force
export alias dote = code (dot source-path)
export def dotu [] {
  dot update --apply
  setup-init
  r
}
export def dotr [] {
  dota
  setup-init
  r
}
