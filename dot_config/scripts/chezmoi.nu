export alias dot = chezmoi
export alias dota = chezmoi apply --force
export alias dote = code (chezmoi source-path)
export def dotu [] {
  hj pull main
  dotr
}
export def dotr [] {
  dota
  setup-init
  r
}
export def dotp [
  desc: string
] {
  cd (chezmoi source-path)
  hj cm $"Update: ($desc)" -p
}
