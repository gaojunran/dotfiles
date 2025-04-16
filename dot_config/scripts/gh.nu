# Quickly clone a repo in Github. 📢 Requires `gh`, `glow` and `fzf` installed. 
export def gc --env [
    name: string # allow 3 kinds of input: owner/repo, @owner, repo
] {
    $env.GH_SEARCH_FIELDS = "createdAt,defaultBranch,description,forksCount,fullName,hasDownloads,hasIssues,hasPages,hasProjects,hasWiki,homepage,id,isArchived,isDisabled,isFork,isPrivate,language,license,name,openIssuesCount,owner,pushedAt,size,stargazersCount,updatedAt,url,visibility,watchersCount"
    $env.GH_CACHE_FILE = "~/.cache/gh/cache.json" | path expand

    mkdir ~/.cache/gh
    
    if ($name | str contains "/") { # have both owner and repo name
        gh repo clone $name
        cd ($name | str substring (($name | str index-of "/") + 1)..($name | str length))
    } else if ($name | str contains "@") { # have owner only, invoke fzf
        let owner = $name | str replace "@" ""
        gh search repos --owner ($owner) --limit 500 --json $env.GH_SEARCH_FIELDS 
            | into string 
            | save -f $env.GH_CACHE_FILE
        open $env.GH_CACHE_FILE 
            | get fullName 
            | to text 
            | fzf --preview "gh repo view {} | glow -" --preview-window right:70%
            | if (($in | str length) > 0) { 
                gh repo clone $in
                cd ($in | str substring (($in | str index-of "/") + 1)..($in | str length))
            }
    } else { # have repo name only, invoke fzf
        gh search repos $name --limit 50 --json $env.GH_SEARCH_FIELDS 
            | into string 
            | save -f $env.GH_CACHE_FILE
        open $env.GH_CACHE_FILE 
            | get fullName
            | to text 
            | fzf --preview "gh repo view {} | glow -" --preview-window right:70%
            | if (($in | str length) > 0) { 
                gh repo clone $in
                cd ($in | str substring (($in | str index-of "/") + 1)..($in | str length))
            }
    }
}

# Quickly earch for a repo in Github. 📢 Requires `gh`, `glow` and `fzf` installed. 
export def gs --env [
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
            | fzf --preview "gh repo view {} | glow -" --preview-window right:70%  --bind "enter:execute(start ('https://github.com/' + {}))"
    } else { # have repo name only, invoke fzf
        gh search repos $name --limit 50 --json $env.GH_SEARCH_FIELDS 
            | into string 
            | save -f $env.GH_CACHE_FILE
        open $env.GH_CACHE_FILE 
            | get fullName
            | to text 
            | fzf --preview "gh repo view {} | glow -" --preview-window right:70%  --bind "enter:execute(start ('https://github.com/' + {}))"
    }
}

# Quickly create a repo in your github, pushing all commits from your pwd. TODO: add more options
export def gn --env [
    name: string # repo name
    desc: string = "" # repo description
] {
    gh repo create $name --source . --push --description $desc --public
}
