export alias as = asdf install
export alias asl = asdf list
export alias ass = asdf set
export alias asi = asdf install
export def asla [plugin: string] {
  asdf list all $plugin | bat
}
