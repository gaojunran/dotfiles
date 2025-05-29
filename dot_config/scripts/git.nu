# Init
export def gi [] {
  git init
  git commit -m "Initial commit" --allow-empty
}

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
    input $"📢 Create ($target) branch from ($source)? \(y/n/<from which branch>\): " | if ($in == "y") {
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
    git stash -u -m $"SWITCH-($source)"
  }
  git switch $target
  let msg = $"SWITCH-($target)"
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
        | fzf -m --preview 'output=$(git diff --color=always -- {}); [ -n "$output" ] && echo "$output" || cat {}' --bind 'pgup:preview-page-up' --preview-window 'right,80%' --bind 'pgdn:preview-page-down' --bind 'ctrl-a:select-all' --reverse
        | lines
        | each { |it| git add $it; print $"📢 Staged ($it)" }
        | ignore
      } else { 
        print "📢 No unstaged changes!" 
      }
}
export def unstage-interactive [] {
  git-status --only-staged 
      | get file 
      | if (($in | length) > 0) { 
        to text
        | fzf -m --preview 'output=$(git diff --staged --color=always -- {}); [ -n "$output" ] && echo "$output" || cat {}' --bind 'pgup:preview-page-up' --preview-window 'right,80%' --bind 'pgdn:preview-page-down' --bind 'ctrl-a:select-all' --reverse
        | lines
        | each { |it| git reset $it; print $"📢 Unstaged ($it)" }
        | ignore
      } else { print "📢 No staged changes!" }
}
export alias st = stage-interactive
export alias unst = unstage-interactive

# ====== Commit ======
export def commit [
  message?: string  # If not given, the command will ask you later.
  --branch (-b): string  # Commit current changes to a specified branch.
  --force (-f)  # Force commit
] {
  if $branch == null {
    # Only allow commit on main branch if there's only one main branch.
    if ((current-branch) == (master-or-main) and (branch-count) > 1 and not $force) {
      print $"(ansi red_bold)⚠️ Do not commit on master/main branch! Use `--force` to force commit.(ansi reset)"
      return
    }
    stage-interactive
    let message = if $message == null {
      input $"📢 Commit message: "
    } else { $message }
    if (git-status --only-staged | length) > 0 and $message != "" {
      git commit -m $message
    }
  } else {
    # Use cherry-pick instead of `integrate`.
    let source = (current-branch)
    if $source == $branch {
      print $"(ansi red_bold)❌ Source branch and target branch are the same. Switch to another branch first.(ansi reset)"
      return
    }
    commit --force $message
    let hash = git rev-parse HEAD
    smart-switch $branch
    git cherry-pick $hash
    smart-switch $source
    reset --hard
    smart-switch $branch
  }
}
  

export def cm [message?: string] {
  commit $message
}
export def cmf [message?: string] {
  commit $message --force
}
export def cmb [branch: string, message?: string] {
  commit $message --branch $branch
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
    print $"(ansi red_bold)❌ Do not force push on master/main branch!(ansi reset)"
    return  
  }
  git push -u origin HEAD -f
}
export alias pl = git pull --rebase --autostash

# Sync latest changes from main branch (by default, or specified branch) and corporate into current branch.
# Now current branch is: latest main branch -> current branch changes.
# After this command, you may want to push current branch and open a pull request.
export def sync [
  branch?: string
] {
  let target = (current-branch)
  let source = $branch | default (master-or-main)
  if ($source == $target) {
    print $"(ansi red_bold)❌ Source branch and target branch are the same. Switch to another branch first.(ansi reset)"
    return
  }
  # Sync remote fork from its parent.
  print $"(ansi blue_bold)🚀 Syncing your fork from its upstream...(ansi reset)"
  let remote_status = git remote get-url origin | complete
  if ($remote_status.exit_code != 0) {
    print "📢 No remote origin. Skip."
  } else {
    let remote = ($remote_status.stdout | str trim)
    let remote_sync_status = gh repo sync ($remote) | complete
    if ($remote_sync_status.exit_code != 0) {
      print "📢 This repo is not a fork. Skip."
    } else {
      print $remote_sync_status.stdout
    }
    # Update main branch from origin.
    print $"(ansi blue_bold)🚀 Updating ($source) branch from origin...(ansi reset)"
    smart-switch $source
    git pull --rebase origin $source
  }
  # Apply changes onto current branch.
  print $"(ansi blue_bold)🚀 Applying ($source) changes onto ($target)...(ansi reset)"
  smart-switch $target
  git stash -u # to make sure rebase works well
  git rebase $source
  git stash pop | complete | ignore
}

# Simply integrate current branch into main branch (by default, or specified branch) using fast-forward merge.
# After this command, you may want to push both branches to remote.
export def integrate [
  branch?: string
] {
  let source = (current-branch)
  let target = $branch | default (master-or-main)
  if ($source == $target) {
    print $"(ansi red_bold)❌ Source branch and target branch are the same. Switch to another branch first.(ansi reset)"
    return
  }
  sync $target
  print $"(ansi blue_bold)🚀 Integrating ($source) branch into ($target) branch...(ansi reset)"
  smart-switch $target
  git merge $source --ff-only
}
export alias inte = integrate

export def discard-interactive [] {
  git-status
      | get file 
      | if (($in | length) > 0) { 
        to text 
        | fzf -m --preview 'output=$(git diff HEAD --color=always -- {}); [ -n "$output" ] && echo "$output" || cat {}' --bind 'pgup:preview-page-up' --bind 'pgdn:preview-page-down' --bind 'ctrl-a:select-all' --reverse
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
      } else { print "📢 Nothing to discard!" }
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

export def extract-sha1 [
  text: string
] {
  $text | parse --regex '.*?(?P<hash>[0-9a-f]{6,}).*' | get hash | get 0
}

export def checkout [
  sha1?: string # invoke fzf if not given
  --all (-a)   # list all actions (git reflog) instead of simply commit history (git log)
] {
  if ($sha1 == null) {
    if $all { git reflog } else { git log --oneline }  
      | if ($in | str length) > 0 { 
          fzf --preview="nu -l -c \"extract-sha1 {} | git show\"" 
          | if ($in | str length) > 0 {
              git checkout (extract-sha1 $in)
            }
        }
  } else {
    git checkout $sha1
  }
}

export alias ch = checkout
export alias cha = checkout --all
export alias chh = checkout HEAD
