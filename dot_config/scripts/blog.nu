export def "bookmark upsert" [
  name: string
  creator: string
  url: string
  type?: string = "post"
] {
  http post https://hdkblvelohkgydorpcbq.supabase.co/rest/v1/rpc/bash_upsert_action (
    { "_name": $name, "_creator": $creator, "_url": $url, "_type": $type } | to json
  ) --headers [
    apikey $env.BLOG_SUPABASE_CLIENT_ANON_KEY 
    Authorization $"Bearer ($env.BLOG_SUPABASE_CLIENT_ANON_KEY)" 
    "Content-Type" "application/json"
  ] | if $in == true {
    print $"(ansi blue_bold)📢 Bookmark inserted.(ansi reset)"
    bookmark list
  } else if $in == false {
    print $"(ansi blue_bold)📢 Bookmark updated.(ansi reset)"
    bookmark list
  }

}

export def "bookmark list" [
  type?: string
] {
  let data = http get https://hdkblvelohkgydorpcbq.supabase.co/rest/v1/bash_select_view?select=* --headers [
    apikey $env.BLOG_SUPABASE_CLIENT_ANON_KEY 
    Authorization $"Bearer ($env.BLOG_SUPABASE_CLIENT_ANON_KEY)"
  ]
  if $type != null {
    $data | where type == $type
  } else {
    $data
  }
}

export def "bookmark delete" [
  query: string
] {
  http post https://hdkblvelohkgydorpcbq.supabase.co/rest/v1/rpc/bash_delete_action (
    { "query": $query } | to json
  ) --headers [
    apikey $env.BLOG_SUPABASE_CLIENT_ANON_KEY 
    Authorization $"Bearer ($env.BLOG_SUPABASE_CLIENT_ANON_KEY)" 
    "Content-Type" "application/json"
  ] | if $in == true {
    print $"(ansi green_bold)📢 Bookmark deleted.(ansi reset)"
    bookmark list
  } else {
    print $"(ansi red_bold)📢 Bookmark not found.(ansi reset)"
  }
}

export alias bm = bookmark upsert
