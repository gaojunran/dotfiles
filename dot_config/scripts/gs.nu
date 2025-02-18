# Quickly clone a repo in Github. 📢 Requires `gh` and `fzf` installed. In the preview panel, press TAB to toggle README of the selected repo.
def gc --env [
    name: string # allow 3 kinds of input: owner/repo, @owner, repo
] {
    $env.GH_SEARCH_FIELDS = "createdAt,defaultBranch,description,forksCount,fullName,hasDownloads,hasIssues,hasPages,hasProjects,hasWiki,homepage,id,isArchived,isDisabled,isFork,isPrivate,language,license,name,openIssuesCount,owner,pushedAt,size,stargazersCount,updatedAt,url,visibility,watchersCount"
    $env.GH_CACHE_FILE = "~/.cache/gh/cache.json" | path expand

    mkdir ~/.cache/gh
    
    if ($name | str contains "/") { # have both owner and repo name
        gh repo clone $name
    } else if ($name | str contains "@") { # have owner only, invoke fzf
        let owner = $name | str replace "@" ""
        gh search repos --owner ($owner) --limit 500 --json $env.GH_SEARCH_FIELDS 
            | into string 
            | save -f $env.GH_CACHE_FILE
        open $env.GH_CACHE_FILE 
            | get name 
            | to text 
            | fzf --preview ("open " + $env.GH_CACHE_FILE + " | where fullName == {} | first") --preview-window right:70% --bind "tab:change-preview(gh repo view {})" --bind "focus:change-preview(nu -c ('open ' + $env.GH_CACHE_FILE + ' | where fullName == {} | first'))"
            | if (($in | str length) > 0) { gh repo clone $in }
        
    } else { # have repo name only, invoke fzf
        gh search repos $name --limit 50 --json $env.GH_SEARCH_FIELDS 
            | into string 
            | save -f $env.GH_CACHE_FILE
        open $env.GH_CACHE_FILE 
            | get fullName
            | to text 
            | fzf --preview ("open " + $env.GH_CACHE_FILE + " | where fullName == {} | first") --preview-window right:70% --bind "tab:change-preview(gh repo view {})" --bind "focus:change-preview(nu -c ('open ' + $env.GH_CACHE_FILE + ' | where fullName == {} | first'))"
            | if (($in | str length) > 0) { gh repo clone $in }
    }
}

# Quickly earch for a repo in Github. 📢 Requires `gh` and `fzf` installed. In the preview panel, press TAB to toggle README of the selected repo.
def gs --env [
    name: string # allow 3 kinds of input: owner/repo, @owner, repo
] {
    $env.GH_SEARCH_FIELDS = "createdAt,defaultBranch,description,forksCount,fullName,hasDownloads,hasIssues,hasPages,hasProjects,hasWiki,homepage,id,isArchived,isDisabled,isFork,isPrivate,language,license,name,openIssuesCount,owner,pushedAt,size,stargazersCount,updatedAt,url,visibility,watchersCount"
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
            | fzf --preview ("open " + $env.GH_CACHE_FILE + " | where fullName == {} | first") --preview-window right:70% --bind "tab:change-preview(gh repo view {})" --bind "focus:change-preview(nu -c ('open ' + $env.GH_CACHE_FILE + ' | where fullName == {} | first'))" --bind "enter:execute(start ('https://github.com/' + {}))"
            # | if (($in | str length) > 0) { start ("https://github.com/" + $in) }
    } else { # have repo name only, invoke fzf
        gh search repos $name --limit 50 --json $env.GH_SEARCH_FIELDS 
            | into string 
            | save -f $env.GH_CACHE_FILE
        open $env.GH_CACHE_FILE 
            | get fullName
            | to text 
            | fzf --preview ("open " + $env.GH_CACHE_FILE + " | where fullName == {} | first") --preview-window right:70% --bind "tab:change-preview(gh repo view {})" --bind "focus:change-preview(nu -c ('open ' + $env.GH_CACHE_FILE + ' | where fullName == {} | first'))" --bind "enter:execute(start ('https://github.com/' + {}))"
            # | if (($in | str length) > 0) { start ("https://github.com/" + $in) }
    }
}
