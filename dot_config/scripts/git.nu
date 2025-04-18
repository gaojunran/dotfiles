# Here lists some typical workflows:
# Personal single-branch projects: update from remote `pl` -> commit `cm` -> push `ps`
# Personal two-branch (main + dev) projects: update dev from remote `pl` -> commit `cm` on dev -> sync and integrate into main branch `inte` -> push main `ps`
# Corporate projects: update feat branch from remote if exists `pl` -> commit `cm` -> sync from main `sync` -> push `ps` -> open a pull request


# Init
export def gi [] {
  git config --global init.defaultBranch main
  git init
}

# ====== Status ======
export def git-status [] {
  git status --porcelain | lines | parse "{status} {file}"
}
export def is-clean [] {
  return ((git-status | length) == 0)
}
export def master-or-main [] {
  if (git branch | lines | each { |it| $it | str trim | str replace '* ' ''  } | any { |it| $it == "main" }) {
    return "main"
  } else {
    return "master"
  }
}

# ====== Branches ======
export alias br = git branch
export def has-branch [name: string] {
  return (git branch | lines | each { |it| $it | str trim | str replace '* ' ''  } | any { |it| $it == $name })
}
export def current-branch [] {
  let branch = (git symbolic-ref --short HEAD | complete)

  if $branch.exit_code != 0 {
    return "detached HEAD"
  } else {
    return ($branch.stdout | str trim)
  }
}
export def branch-count [] {
  git branch | lines | length
}

# `br` conflicts with `brew`.
export alias bra = git switch -c
export def brd [branch?: string] {
  let current = (current-branch)
  if ($current == $branch or $current == "detached HEAD" or $branch == null) {
    git switch (master-or-main)
  }
  if ($branch == null) {
    git branch -d $current
  } else {
    git branch -d $branch
  }
}
export alias mst = git switch (master-or-main)
export alias dev = git switch -c dev
export def dev [] {
  if (has-branch 'dev') {
    git switch dev
  } else {
    input "📢 Create dev branch? (y/n): " | if ($in == "y") {
      git switch (master-or-main)
      git switch -c dev
    }
  }
}
export def feat [name: string] {
  if (has-branch ('feat/' + $name)) {
    git switch $name
  } else {
    input "📢 Create this branch? (y/n): " | if ($in == "y") {
      git switch -c ('feat/' + $name)
    }
  }
}
export def fix [name: string] {
  if (has-branch ('fix/' + $name)) {
    git switch $name
  } else {
    input "📢 Create this branch? (y/n): " | if ($in == "y") {
      git switch -c ('fix/' + $name)
    }
  }
}

# ====== Commit ======

# Run `cm` without args when you want to commit. It'll stage all changes and show diff.
# After checking diff, you can run `cm` again with a commit message to actually commit.
export def cm [message?: string] {
  # Only allow commit on main branch if there's only one main branch.
  if ((current-branch) == (master-or-main) and (branch-count) > 1) {
    print "⚠️ Do not commit on master/main branch!"
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
export def psf [] {
  # Only allow force push on main branch if there's only one main branch.
  if ((current-branch) == (master-or-main) and (branch-count) > 1) {
    print "❌ Do not force push on master/main branch!"
    return  
  }
  git push -u origin HEAD -f
}
export alias pl = git pull --rebase

# Sync latest changes from main branch, and corporate into current branch.
# Now current branch is: latest main branch -> current branch changes.
# After this command, you may want to push current branch and open a pull request.
export def sync [] {
  if not (is-clean) {
    print "⚠️ Working directory is not clean. Please commit or stash your changes: "
    git-status
    return
  }
  print "🚀 Syncing your fork from its parent..."
  let current = (current-branch)
  let master_or_main = (master-or-main)
  if ($current == $master_or_main) {
    print "📢 You are on master/main branch. This action will only update master/main branch."
  }

  # Sync remote fork from its parent.
  let res = gh repo sync (git remote get-url origin) | complete
  if ($res.exit_code != 0) {
    print "📢 This repo is not a fork. Skip."
  } else {
    print $res.stdout
  }
  # Update main branch from origin.
  print "🚀 Updating master/main branch from origin..."
  git switch $master_or_main
  git pull --rebase origin $master_or_main
  # Apply changes onto current branch.
  print "🚀 Applying changes onto current branch..."
  git switch $current
  git rebase $master_or_main
}

# For some small personal projects, simply integrate current branch into main branch.
# Use it after you finish several commits on a branch.
# After this command, you may want to push both branches to remote.
export def inte [] {
  let current = (current-branch)
  let master_or_main = (master-or-main)
  if ($current == $master_or_main) {
    print "❌ This action is not applicable to master/main branch. Switch to another branch first."
    return
  }
  sync
  print "🚀 Integrating current branch into master/main branch..."
  git switch $master_or_main
  git merge $current --ff-only
}

# ====== Undo Operations ======
