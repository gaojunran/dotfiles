# Init
export def gi [] {
  git config --global init.defaultBranch main
  git init
  git switch -c dev
}

# ====== Status ======
export def git-status [] {
  git status --porcelain | lines | parse "{status} {file}"
}
export def is-clean [] {
  return ((git-status | length) == 0)
}

# ====== Branches ======
export alias br = git switch
export def has-branch [name: string] {
  return (git branch | lines | each { |it| $it | str trim | str replace '* ' ''  } | any { |it| $it == $name })
}
export def current-branch [] {
  let git_output = (git rev-parse --abbrev-ref HEAD | str trim)
  if ($git_output == "HEAD") {
    return "detached HEAD"
  } else {
    return $git_output
  }
}
# `br` conflicts with `brew`.
export alias bra = git switch -c
export def brd [branch?: string] {
  let current = (current-branch)
  if ($current == $branch or $current == "detached HEAD" or $branch == null) {
    git switch main
  }
  if ($branch == null) {
    git branch -d $current
  } else {
    git branch -d $branch
  }
}
export alias mai = git switch main  # avoid conflict with main command
export alias dev = git switch dev
export def feat [name: string] {
  if (has-branch ('feat/' + $name)) {
    git switch $name
  } else {
    git switch -c ('feat/' + $name)
  }
}
export def fix [name: string] {
  if (has-branch ('fix/' + $name)) {
    git switch $name
  } else {
    git switch -c ('fix/' + $name)
  }
}

# ====== Commit ======

# Run `cm` without args when you want to commit. It'll stage all changes and show diff.
# After checking diff, you can run `cm` again with a commit message to actually commit.
export def cm [message?: string, --force (-f)] {
  if ((current-branch) == "main" and not $force) {
    print "⚠️ Do not commit on main branch!"
    return  
  }
  if ($message == null) {
    git add .
    print "📝 All changes are staged. Diff:"
    git diff --cached --numstat 
            | lines | parse "{added}\t{removed}\t{file}" 
            | rename "+" "-" "file" | print
    git diff --cached | bat --style=grid --color=always
  } else {
    git commit -am $message
  }
}
# Show commit history.
export def his [] {
  git log --pretty=%h»¦«%aN»¦«%s»¦«%aD | lines | split column "»¦«" sha1 committer desc merged_at | first 10
}

# ====== Push/Pull/Rebase/Merge ======

export alias ps = git push -u origin HEAD
export alias psm = git push -u origin main
export def psf [
  --force (-f)
] {
  if ((current-branch) == "main" and not $force) {
    print "⚠️ Do not force push on main branch!"
    return  
  }
  git push -u origin HEAD -f
}

# Sync latest changes from main branch, and corporate into current branch.
# Now current branch is: latest main branch -> current branch changes.
# After this command, you may want to push current branch and open a pull request.
export def sync [] {
  if not (is-clean) {
    print "⚠️ Working directory is not clean. Please commit or stash your changes."
    return
  }
  let current = (current-branch)
  if ($current == "main") {
    print "📢 You are on main branch. This action will only update main branch."
  }
  # Update main branch from origin.
  git switch main
  git pull --rebase origin main
  # Rebase changes onto our current branch.
  git switch $current
  git rebase main
}
export def syp [] {
  sync
  ps
}

# For some small personal projects, simply integrate current branch into main branch.
# Use it after you finish several commits on a feature/fix/dev branch.
# After this command, you may want to push main branch to remote.
export def inte [] {
  let current = (current-branch)
  sync
  git switch main
  git merge $current --ff-only
  git switch $current
}
export def itp [] {
  inte
  psm
}

# ====== Undo Operations ======
