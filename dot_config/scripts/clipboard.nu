export alias cc = cb copy
export alias cv = cb paste
export alias cx = cb cut
export alias cvc = cb paste | code -

# Save a clipboard item to a file
export def cs [
  name?: string,
  --append (-a) # use save -a
  --force (-f) # use save -f
] {
  let filename = if $name != null { $name } else { ("output-" + (now-hash) + ".txt") | path expand }
  if $append {
    cb paste | save -a $filename
  } else if $force {
    cb paste | save -f $filename
  } else {
    cb paste | save $filename
  }
  success $"Saved clipboard to ($filename)"
}
export alias ca = cs --append
export alias cf = cs --force
