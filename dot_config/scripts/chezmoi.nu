export alias dot = chezmoi
export alias dota = chezmoi apply --force -k --override-data-file ~/env.local.yaml
export alias dote = zed (chezmoi source-path)
export def dotu [] {
  hj pull main
  dotr
}
export def dotr [] {
  internal dota | complete | ignore  # this command may fail now
  setup-init
  r
}
export def dotp [
  desc: string
] {
  cd (chezmoi source-path)
  hj cm $"Update: ($desc)" -p
  dotr
}
