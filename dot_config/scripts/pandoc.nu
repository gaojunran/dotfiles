export def todocx [] {
  let path = ("output-" + (now-string) + ".docx") | path expand
  cb paste | pandoc -o $path
  start $path
}
