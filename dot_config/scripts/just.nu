# just
export def d [] {
  if (is-installed "zellij") {
    zellij --layout ~/.config/zellij/project-default.kdl
  } else {
    print "zellij is not installed!"
    just dev
  }
}

export alias j = just
export alias b = just build
export alias f = just fmt
export alias t = just test
export alias jr = just run
