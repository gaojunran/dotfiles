# Init
export alias gi = git init

# ====== Status ======
export def git-status [
  --only-staged (-s) 
  --only-unstaged (-u)
] {
  if ($only_staged) {
    git-status | where $it.status !~ '^ [^ ]|^\?\?'
  } else if ($only_unstaged) {
    git-status | where $it.status =~ '^ [^ ]|^\?\?'
  } else {
    git status --porcelain | lines | parse --regex '(?P<status>.{2})\s(?P<file>.*)'
  }
}
export alias gs = git-status
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

export def smart-switch [
  branch?: string # invoke a interactive chooser if not provided
] {
  
  let source = (current-branch)
  let target = if $branch == null {
    git branch 
        | lines | to text 
        | fzf 
        | str replace -r '^[\*|\s]{2}' ''
        | if ($in == "") { return } else { $in }
  } else { $branch }
  if not (has-branch $target) {
    input $"📢 Create `($target)` branch from `($source)`? (y/n/<from which branch>): " | if ($in == "y") {
      git branch $target 
    } else if ($in == "n") {
      return
    } else {
      git branch $target ($in)
    }
  }
  if ($source == $target) {
    print $"📢 Already on branch ($target)"
    return
  }
  if not (is-clean) {
    print "📢 Stashing changes..."
    git stash -u -m $"STASH-($source)"
  }
  git switch $target
  let msg = $"STASH-($target)"
  let ref = git stash list --grep=($msg) --format="%gd"
  if $ref != "" {
    print "📢 Unstashing changes..."
    git stash pop ($ref)
  }
}
export def sw [target?: string] {
  smart-switch $target
}

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
export alias mst = smart-switch (master-or-main)
export alias dev = smart-switch dev


export def stage-interactive [] {
  git-status --only-unstaged 
      | get file 
      | if (($in | length) > 0) { 
        to text 
        | fzf -m --preview 'output=$(git diff --color=always -- {}); [ -n "$output" ] && echo "$output" || cat {}' --bind 'pgup:preview-page-up' --bind 'pgdn:preview-page-down' --bind 'ctrl-a:select-all+accept' --reverse
        | lines
        | each { |it| git add $it; print $"📢 Staged ($it)" }
        | ignore
      } else { print "📢 No unstaged changes!" }
}
export def unstage-interactive [] {
  git-status --only-staged 
      | get file 
      | if (($in | length) > 0) { 
        to text
        | fzf -m --preview 'output=$(git diff --staged --color=always -- {}); [ -n "$output" ] && echo "$output" || cat {}' --bind 'pgup:preview-page-up' --bind 'pgdn:preview-page-down' --bind 'ctrl-a:select-all+accept' --reverse
        | lines
        | each { |it| git reset $it; print $"📢 Unstaged ($it)" }
        | ignore
      } else { print "📢 No staged changes!" }
}
export alias st = stage-interactive
export alias unst = unstage-interactive

# ====== Commit ======
export def commit [
  message: string
  --force (-f)  # Force commit
] {
  # Only allow commit on main branch if there's only one main branch.
  if ((current-branch) == (master-or-main) and (branch-count) > 1 and not $force) {
    print "⚠️ Do not commit on master/main branch! Use `--force` to force commit."
    return
  }
  git commit -am $message
}
export def cm [message: string] {
  commit $message
}
export def cmf [message: string] {
  commit $message --force
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

# Sync latest changes from main branch (by default, or specified branch) and corporate into current branch.
# Now current branch is: latest main branch -> current branch changes.
# After this command, you may want to push current branch and open a pull request.
export def sync [
  branch?: string
] {
  let target = (current-branch)
  let source = $branch | default (master-or-main)
  if ($source == $target) {
    print "❌ Source branch and target branch are the same. Switch to another branch first."
    return
  }
  # Sync remote fork from its parent.
  print "🚀 Syncing your fork from its upstream..."
  let res = gh repo sync (git remote get-url origin) | complete
  if ($res.exit_code != 0) {
    print "📢 This repo is not a fork. Skip."
  } else {
    print $res.stdout
  }
  # Update main branch from origin.
  print $"🚀 Updating ($source) branch from origin..."
  smart-switch $source
  git pull --rebase origin $source
  # Apply changes onto current branch.
  print $"🚀 Applying ($source) changes onto ($target)..."
  smart-switch $target
  git rebase $source
}

# Simply integrate current branch into main branch (by default, or specified branch) using fast-forward merge.
# After this command, you may want to push both branches to remote.
export def integrate [
  branch?: string
] {
  let source = (current-branch)
  let target = $branch | default (master-or-main)
  if ($source == $target) {
    print "❌ Source branch and target branch are the same. Switch to another branch first."
    return
  }
  sync $target
  print $"🚀 Integrating ($source) branch into ($target) branch..."
  smart-switch $target
  git merge $source --ff-only
}
export alias inte = integrate

export def discard-interactive [] {
  git-status
      | get file 
      | if (($in | length) > 0) { 
        to text 
        | fzf -m --preview 'output=$(git diff HEAD --color=always -- {}); [ -n "$output" ] && echo "$output" || cat {}' --bind 'pgup:preview-page-up' --bind 'pgdn:preview-page-down' --bind 'ctrl-a:select-all+accept' --reverse
        | lines
        | each { |it| 
          let output = git restore --source=HEAD --worktree --staged $it | complete
          if ($output.exit_code != 0) { # untracked
            rm -rf $it
            print $"📢 Deleted ($it)"
          } else {
            print $"📢 Discarded ($it)"
          }
        }
        | ignore
      } else { print "📢 No unstaged changes!" }
}
export alias dis = discard-interactive

export def reset [
  count?: int = 1,
  --hard (-h)  # Hard reset
] {
  if ($hard) {
    git reset --hard ("HEAD~" + ($count | into string))
  } else {
    git reset --mixed ("HEAD~" + ($count | into string))
  }
}
