export alias cc = cb copy
export alias cv = cb paste

# Copy specified files / files from the clipboard, to ~/Playground/<dir>.
export def --env cvp [
	dir?: string,  # Specify a dir name. It'll be ~/Playground/<dir>.
	...files: string # Specify files to copy. If empty, copy from clipboard.
] {
	let abs_files = $files | each { |file| $file | path expand }
	cd ~/Playground
	if ($dir != null) {
		mc $dir
	}
	if (($files | length) > 0) {
		$abs_files | each { | file | !cp $file ($file | path basename) }
	} else {
		cb paste
	}
	ls -a
}
