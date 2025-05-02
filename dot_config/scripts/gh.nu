def clone-and-cd --env [
  fullName: string,
  --degit (-d) # use degit mode, internally use `tiged`
] {
  let repoName = ($fullName | str substring (($fullName | str index-of "/") + 1)..)
  if $degit {
    mc $repoName
    tiged $fullName
  } else {
    gh repo clone $fullName
    cd $repoName
  }
}

def parse-url [url: string] {
  $url 
  | parse --regex 'http[s]?\://github.com/(?P<owner>[^/]+)/(?P<repo>[^/]+).*'
  | first
  | ($in.owner + "/" + $in.repo)
}

# Quickly clone a repo in Github. 📢 Requires `gh`, `glow` and `fzf` installed. 
export def clone --env [
  name?: string # allow 4 kinds of input: url, owner/repo, @owner, repo
  --degit (-d) # use degit mode, internally use `tiged`
] {
  if $name == null {
    if not (is-macos) {
        print "❌ Not implemented on non-macOS yet."
        return
    }
    print "Currently only Arc Browser is supported."
    let script = open ~/.config/scripts/get_arc_tabs.applescript | to text
    osascript -e $script
        | from json
        | get url
        | where $it =~ 'http[s]?\://github.com/.*'
        | each { |it| parse-url $it }
        | uniq
        | to text
        | fzf --height=~100%  # not full screen
        | if (($in | str length) > 0) {
            if $degit { clone-and-cd -d $in } else { clone-and-cd $in }
        }
  } else if ($name =~ 'http[s]?\://github.com/.*') {
    # Format: url, allow sub-url of the repo
    if $degit { clone-and-cd -d (parse-url $name) } else { clone-and-cd (parse-url $name) }
  } else if ($name | str contains "!") {
    # Format: !repo, owner is current user of gh
    # tiged do not support clone "my" repo, so `-d` does not work here
    gh repo clone ($name | str replace "!" "")
    cd ($name | str replace "!" "")
  } else if ($name | str contains "/") { 
    # Format: owner/repo
    if $degit { clone-and-cd -d $name } else { clone-and-cd $name }
  } else if ($name | str contains "@") { 
    # Format: @owner
    let owner = $name | str replace "@" ""
    gh search repos --owner $owner --limit 500 --json fullName
      | into string
      | from json
      | get fullName
      | to text
      | fzf --preview "gh repo view {} | glow - --style=dark" --preview-window right:70%
      | if (($in | str length) > 0) {
          if $degit { clone-and-cd -d $in } else { clone-and-cd $in }
        }
  } else { 
    # Format: repo name only
    gh search repos $name --limit 50 --json fullName
      | get fullName
      | to text
      | fzf --preview "gh repo view {} | glow - --style=dark" --preview-window right:70%
      | if (($in | str length) > 0) {
          if $degit { clone-and-cd -d $in } else { clone-and-cd $in }
        }
  }
}
export alias dg = clone -d



# Quickly search for a repo in Github, to check its README or open its github homepage. 📢 Requires `gh`, `glow` and `fzf` installed. 
# TO BE REVISED
export def repo --env [
    name: string # allow 3 kinds of input: owner/repo, @owner, repo
] {
    $env.GH_SEARCH_FIELDS = "createdAt,defaultBranch,description,forksCount,fullName,hasDownloads,hasIssues,hasPages,hasProjects,hasWiki,homepage,id,isArchived,isDisabled,isFork,isPrivate,language,license,name,openIssuesCount,owner,pushedAt,size,stargazersCount,updatedAt,url,visibility,watchersCount"  # TODO: only use the fields we need
    $env.GH_CACHE_FILE = "~/.cache/gh/cache.json" | path expand

    mkdir ~/.cache/gh
    
    if ($name | str contains "/") { # have both owner and repo name
        start ("https://github.com/" + $name)
    } else if ($name | str contains "@") { # have owner only, invoke fzf
        let owner = $name | str replace "@" ""
        gh search repos --owner ($owner) --limit 500 --json $env.GH_SEARCH_FIELDS 
            | into string 
            | save -f $env.GH_CACHE_FILE
        open $env.GH_CACHE_FILE 
            | get fullName 
            | to text 
            | fzf --preview "gh repo view {} | glow - --style=dark" --preview-window right:70%  --bind "enter:execute(start ('https://github.com/' + {}))"
    } else { # have repo name only, invoke fzf
        gh search repos $name --limit 50 --json $env.GH_SEARCH_FIELDS 
            | into string 
            | save -f $env.GH_CACHE_FILE
        open $env.GH_CACHE_FILE 
            | get fullName
            | to text 
            | fzf --preview "gh repo view {} | glow - --style=dark" --preview-window right:70%  --bind "enter:execute(start ('https://github.com/' + {}))"
    }
}

# Quickly create a repo in your github, pushing all commits from your pwd. TODO: add more options
export def rn --env [
    name: string # repo name
    desc: string = "" # repo description
] {
    gh repo create $name --source . --push --description $desc --public
}
export alias rx = gh repo delete

export alias pr = gh pr
export alias prn = gh pr create

export def demo [--test (-t)] {
  print $test
}
