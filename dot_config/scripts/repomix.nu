# mix the whole repo, or a remote repo
export def mix [gh_repo?: string, include?: string, exclude?: string] {
  
  if ($gh_repo != null) {
    mkdir ~/repomix
    let filepath = "~/repomix" | path expand | path join (($gh_repo | str replace "/" "-") + ".txt")
    # print $filepath
    # mix a remote repo
    if ($include != null and $exclude != null) {
      repomix --copy --output $filepath --remote $gh_repo --include $include --ignore $exclude
    } else if ($include != null) {
      repomix --copy --output $filepath --remote $gh_repo --include $include
    } else if ($exclude != null) {
      repomix --copy --output $filepath --remote $gh_repo --ignore $exclude
    } else {
      repomix --copy --output $filepath --remote $gh_repo
    }
  } else {
    # mix cwd
    # If .gitignore is present, add `repomix-output.txt` to it
    if (".gitignore" | path exists) {
      if (not (cat ".gitignore" | lines | any { |it| $it | str contains "repomix-output.txt" })) {
        "repomix-output.txt" | save --append .gitignore
      }
    } else {
      "repomix-output.txt" | save .gitignore
    }
    if ($include != null and $exclude != null) {
      repomix --copy --output "repomix-output.txt" --include $include --ignore $exclude
    } else if ($include != null) {
      repomix --copy --output "repomix-output.txt" --include $include
    } else if ($exclude != null) {
      repomix --copy --output "repomix-output.txt" --ignore $exclude
    } else {
      repomix --copy --output "repomix-output.txt"
    }
  }
}
